defmodule Screens.V3Api do
  @moduledoc false

  use Retry.Annotation

  require Logger

  alias __MODULE__.Cache

  @default_opts [
    timeout: 5000,
    recv_timeout: 5000,
    hackney: [pool: :api_v3_pool, checkout_timeout: 4000]
  ]

  def get_json(path, params \\ %{}, opts \\ []) do
    ctx = Screens.Telemetry.context()
    meta = Map.merge(ctx, %{path: path, query: URI.encode_query(params)})

    Screens.Telemetry.span_with_stop_meta([:screens, :v3_api, :get_json], meta, fn ->
      case Cache.get({path, params}) do
        {:fresh, {_last_modified, response}} ->
          {{:ok, response}, %{cache: "local"}}

        {:stale, {last_modified, response}} ->
          fetch_json_with_meta(path, params, opts, last_modified, response)

        nil ->
          fetch_json_with_meta(path, params, opts)
      end
    end)
  end

  @retry with: Stream.take(constant_backoff(500), 3), atoms: [:bad_response_code]
  defp fetch_json_with_meta(path, params, opts, last_modified \\ nil, cached_response \\ nil) do
    url = build_url(path, params)
    api_key = Application.get_env(:screens, :api_v3_key)
    headers = api_key_headers(api_key) ++ cache_headers(last_modified)

    case HTTPoison.get(url, headers, Keyword.merge(@default_opts, opts)) do
      {:ok, %{status_code: 200, body: body, headers: headers}} ->
        response = Jason.decode!(body)
        last_modified = headers |> Map.new() |> Map.fetch!("last-modified")
        Cache.put({path, params}, {last_modified, response})
        {{:ok, response}, %{cache: "none"}}

      {:ok, %{status_code: 304}} ->
        # Refresh unconditional TTL on the cache entry
        Cache.put({path, params}, {last_modified, cached_response})
        {{:ok, cached_response}, %{cache: "http"}}

      {:ok, %{status_code: status_code}} ->
        log_api_error(:bad_response_code, url, status_code: status_code)
        {:bad_response_code, %{}}

      {:error, error} ->
        log_api_error(:http_fetch_error, url, message: Exception.message(error))
        {{:http_fetch_error, error}, %{}}
    end
  end

  defp log_api_error(error_type, url, extra_fields) do
    extra_fields
    |> Enum.map_join(" ", fn {label, value} -> "#{label}=\"#{value}\"" end)
    |> then(fn fields ->
      Logger.error("api_v3_get_json_error url=\"#{url}\" error_type=#{error_type} " <> fields)
    end)
  end

  defp build_url(path, params) do
    :screens
    |> Application.get_env(:api_v3_url)
    |> URI.parse()
    |> URI.merge(path)
    |> URI.to_string()
    |> then(fn uri ->
      if map_size(params) == 0, do: uri, else: "#{uri}?#{URI.encode_query(params)}"
    end)
  end

  defp api_key_headers(nil), do: []
  defp api_key_headers(key), do: [{"x-api-key", key}]

  defp cache_headers(nil), do: []
  defp cache_headers(last_modified), do: [{"if-modified-since", last_modified}]
end
