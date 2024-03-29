defmodule Screens.V3Api do
  @moduledoc false

  use Retry.Annotation

  require Logger

  @default_opts [
    timeout: 5000,
    recv_timeout: 5000,
    hackney: [pool: :api_v3_pool, checkout_timeout: 4000]
  ]

  @retry with: Stream.take(constant_backoff(500), 3), atoms: [:bad_response_code]
  def get_json(
        route,
        params \\ %{},
        extra_headers \\ [],
        opts \\ [],
        return_with_headers \\ false
      ) do
    headers = extra_headers ++ api_key_headers(Application.get_env(:screens, :api_v3_key))
    url = build_url(route, params)

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
      if return_with_headers do
        {:ok, parsed, headers}
      else
        {:ok, parsed}
      end
    else
      {:http_request, e} ->
        {:error, httpoison_error} = e

        log_api_error({:http_fetch_error, e}, url, message: Exception.message(httpoison_error))

      {:response_success, %{status_code: 304}} ->
        :not_modified

      {:response_success, %{status_code: status_code}} = response ->
        _ = log_api_error({:bad_response_code, response}, url, status_code: status_code)

        :bad_response_code

      {:parse, {:error, e}} ->
        log_api_error({:parse_error, e}, url)

      e ->
        log_api_error({:error, e}, url)
    end
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
    :screens
    |> Application.get_env(:environment_name)
    |> base_url_for_environment()
  end

  defp base_url_for_environment(environment_name) do
    case environment_name do
      "screens-prod" -> "https://api-v3.mbta.com/"
      "screens-dev" -> "https://api-dev.mbtace.com/"
      "screens-dev-green" -> "https://api-dev-green.mbtace.com/"
      _ -> Application.get_env(:screens, :default_api_v3_url)
    end
  end

  defp api_key_headers(nil), do: []
  defp api_key_headers(key), do: [{"x-api-key", key}]
end
