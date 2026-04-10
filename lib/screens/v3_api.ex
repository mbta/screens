defmodule Screens.V3Api do
  @moduledoc false

  alias __MODULE__.Cache

  @request_opts [finch: __MODULE__.Finch]

  @spec get_json(path :: String.t(), params :: %{String.t() => String.t()}) ::
          {:ok, term()} | {:error, Exception.t()}
  def get_json(path, params) do
    ctx = Screens.Telemetry.context()
    meta = Map.merge(ctx, %{path: path, query: URI.encode_query(params)})

    Screens.Telemetry.span_with_stop_meta([:screens, :v3_api, :get_json], meta, fn ->
      case Cache.get({path, params}) do
        {:fresh, {_last_modified, response}} ->
          {{:ok, response}, %{cache: "local"}}

        {:stale, {last_modified, response}} ->
          fetch_json_with_meta(path, params, last_modified, response)

        nil ->
          fetch_json_with_meta(path, params)
      end
    end)
  end

  defp fetch_json_with_meta(path, params, last_modified \\ nil, cached_body \\ nil) do
    url = build_url(path, params)
    api_key = Application.get_env(:screens, :api_v3_key)
    headers = api_key_headers(api_key) ++ cache_headers(last_modified)

    case Req.get(url, Keyword.put(@request_opts, :headers, headers)) do
      {:ok, %Req.Response{status: 200, body: body, headers: headers}} ->
        [last_modified] = Map.fetch!(headers, "last-modified")
        Cache.put({path, params}, {last_modified, body})
        {{:ok, body}, %{cache: "none"}}

      {:ok, %Req.Response{status: 304}} ->
        # Refresh unconditional TTL on the cache entry
        Cache.put({path, params}, {last_modified, cached_body})
        {{:ok, cached_body}, %{cache: "http"}}

      {:error, error} ->
        Logster.error(["api_v3_fetch_error", url: url, error: inspect(error)])
        {{:error, error}, %{}}
    end
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
