defmodule Screens.V3Api do
  @moduledoc false

  @default_opts [timeout: 2000, recv_timeout: 2000]
  @base_url "https://api-v3.mbta.com/"

  def get_json(path, extra_headers \\ [], opts \\ []) do
    headers = extra_headers ++ api_key_headers(Application.get_env(:screens, :api_v3_key))

    with {:http_request, {:ok, response}} <-
           {:http_request,
            HTTPoison.get(
              @base_url <> path,
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

  defp api_key_headers(nil), do: []
  defp api_key_headers(key), do: [{"x-api-key", key}]
end
