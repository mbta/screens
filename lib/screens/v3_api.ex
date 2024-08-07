defmodule Screens.V3Api do
  @moduledoc false

  use Retry.Annotation

  require Logger

  alias Screens.ScreenApiResponseCache

  @default_opts [
    timeout: 5000,
    recv_timeout: 5000,
    hackney: [pool: :api_v3_pool, checkout_timeout: 4000]
  ]

  @retry with: Stream.take(constant_backoff(500), 3), atoms: [:bad_response_code]
  def get_json(
        route,
        params \\ %{},
        opts \\ []
      ) do
    headers = api_key_headers(Application.get_env(:screens, :api_v3_key))
    url = build_url(route, params)

    ctx = Screens.Telemetry.context()

    meta =
      Map.merge(ctx, %{url: url})

    Screens.Telemetry.span_with_stop_meta([:screens, :v3_api, :get_json], meta, fn ->
      cached_response = ScreenApiResponseCache.get(url)

      headers =
        if is_nil(cached_response),
          do: headers,
          else: headers ++ [{"if-modified-since", elem(cached_response, 1)}]

      with {:http_request, {:ok, response}} <-
             {:http_request,
              HTTPoison.get(
                url,
                headers,
                Keyword.merge(@default_opts, opts)
              )},
           {:response_success, %{status_code: 200, body: body, headers: headers}} <-
             {:response_success, response},
           {:parse, {:ok, parsed}} <- {:parse, Jason.decode(body)} do
        update_response_cache(url, parsed, headers)

        {{:ok, parsed}, %{cached: false}}
      else
        {:http_request, e} ->
          {:error, httpoison_error} = e

          error =
            log_api_error({:http_fetch_error, e}, url,
              message: Exception.message(httpoison_error)
            )

          {error, %{cached: false}}

        {:response_success, %{status_code: 304}} ->
          {{:ok, elem(cached_response, 0)}, %{cached: true}}

        {:response_success, %{status_code: status_code}} = response ->
          _ = log_api_error({:bad_response_code, response}, url, status_code: status_code)

          {:bad_response_code, %{cached: false}}

        {:parse, {:error, e}} ->
          error = log_api_error({:parse_error, e}, url)
          {error, %{cached: false}}

        e ->
          error = log_api_error({:error, e}, url)
          {error, %{cached: false}}
      end
    end)
  end

  defp update_response_cache(url, response, headers) do
    date =
      headers
      |> Enum.into(%{})
      |> Map.get("last-modified")

    ScreenApiResponseCache.put(url, {response, date})
  end

  defp log_api_error({error_type, _error_data} = error, url, extra_fields \\ []) do
    extra_fields
    |> Enum.map_join(" ", fn {label, value} -> "#{label}=\"#{value}\"" end)
    |> then(fn fields ->
      Logger.info("[api_v3_get_json_error] url=\"#{url}\" error_type=#{error_type} " <> fields)
    end)

    error
  end

  defp build_url(route, params) when map_size(params) == 0 do
    base_url()
    |> URI.parse()
    |> URI.merge(route)
    |> URI.to_string()
  end

  defp build_url(route, params) do
    base_url()
    |> URI.parse()
    |> URI.merge(route)
    |> URI.to_string()
    |> then(&"#{&1}?#{URI.encode_query(params)}")
  end

  defp base_url do
    Application.get_env(:screens, :api_v3_url)
  end

  defp api_key_headers(nil), do: []
  defp api_key_headers(key), do: [{"x-api-key", key}]
end
