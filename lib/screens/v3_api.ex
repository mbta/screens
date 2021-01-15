defmodule Screens.V3Api do
  @moduledoc false

  require Logger

  @default_opts [timeout: 2000, recv_timeout: 2000, hackney: [pool: :api_v3_pool]]

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
        log_api_error({:http_fetch_error, e})

      {:response_success, %{status_code: _status_code}} = response ->
        log_api_error({:bad_response_code, response})

      {:parse, {:error, e}} ->
        log_api_error({:parse_error, e})

      e ->
        log_api_error({:error, e})
    end
  end

  defp log_api_error({error_type, _error_data} = error) do
    _ = Logger.info("[api_v3_get_json_error] error_type=#{error_type}")

    error
  end

  defp build_url(route, params) when map_size(params) == 0 do
    base_url() <> route
  end

  defp build_url(route, params) do
    "#{base_url()}#{route}?#{URI.encode_query(params)}"
  end

  defp base_url do
    Application.get_env(:screens, :api_v3_url)
  end

  defp api_key_headers(nil), do: []
  defp api_key_headers(key), do: [{"x-api-key", key}]
end
