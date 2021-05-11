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
        {:error, httpoison_error} = e
        log_api_error({:http_fetch_error, e}, message: Exception.message(httpoison_error))

      {:response_success, %{status_code: status_code}} = response ->
        log_api_error({:bad_response_code, response}, status_code: status_code)

      {:parse, {:error, e}} ->
        log_api_error({:parse_error, e})

      e ->
        log_api_error({:error, e})
    end
  end

  defp log_api_error({error_type, _error_data} = error, extra_fields \\ []) do
    extra_fields =
      extra_fields
      |> Enum.map(fn {label, value} -> "#{label}=#{value}" end)
      |> Enum.join(" ")

    _ = Logger.info("[api_v3_get_json_error] error_type=#{error_type} " <> extra_fields)

    error
  end

  defp build_url(route, params) when map_size(params) == 0 do
    base_url() <> route
  end

  defp build_url(route, params) do
    "#{base_url()}#{route}?#{URI.encode_query(params)}"
  end

  defp base_url do
    :screens
    |> Application.get_env(:environment_name)
    |> base_url_for_environment()
  end

  defp base_url_for_environment(environment_name) do
    case environment_name do
      "screens-prod" -> "https://api-v3.mbta.com/"
      "screens-dev" -> "https://dev.api.mbtace.com/"
      "screens-dev-green" -> "https://green.dev.api.mbtace.com/"
      _ -> Application.get_env(:screens, :default_api_v3_url)
    end
  end

  defp api_key_headers(nil), do: []
  defp api_key_headers(key), do: [{"x-api-key", key}]
end
