defmodule Screens.V3Api do
  @moduledoc false

  @default_opts [timeout: 2000, recv_timeout: 2000, hackney: [pool: :api_v3_pool]]
  @base_url Application.get_env(:screens, :api_v3_url)

  def get_json(route, params \\ %{}, extra_headers \\ [], opts \\ []) do
    headers = extra_headers ++ api_key_headers(Application.get_env(:screens, :api_v3_key))
    url = build_url(route, params)

    with {:http_request, {:ok, response}} <-
           {:http_request,
            HTTPoison.get(
              url,
              headers,
              Keyword.merge(@default_opts, opts)
            )},
         {:response_success, %{status_code: 200, body: body}} <- {:response_success, response},
         {:parse, {:ok, parsed}} <- {:parse, Jason.decode(body)} do
      {:ok, parsed}
    else
      {:http_request, e} ->
        {:http_fetch_error, e}

      {:response_success, %{status_code: _status_code}} = response ->
        {:bad_response_code, response}

      {:parse, {:error, e}} ->
        {:parse_error, e}

      e ->
        {:error, e}
    end
  end

  defp build_url(route, params) when map_size(params) == 0 do
    @base_url <> route
  end

  defp build_url(route, params) do
    "#{@base_url}#{route}?#{URI.encode_query(params)}"
  end

  defp api_key_headers(nil), do: []
  defp api_key_headers(key), do: [{"x-api-key", key}]
end
