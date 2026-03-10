defmodule Screens.DeviceMonitor.Fetch do
  @moduledoc "Shared data fetching logic for device monitor modules."

  @spec make_and_parse_request(
          url :: binary(),
          HTTPoison.headers(),
          http_opts :: Keyword.t(),
          parse_fn :: (binary() -> {:ok, parsed} | {:error, term()}),
          vendor_name :: atom()
        ) :: {:ok, parsed} | :error
        when parsed: any()
  def make_and_parse_request(url, headers, opts, parse_fn, vendor_name) do
    with {:http_request, {:ok, response}} <- {:http_request, HTTPoison.get(url, headers, opts)},
         {:response_success, %{status_code: 200, body: body}} <- {:response_success, response},
         {:parse, {:ok, parsed}} <- {:parse, parse_fn.(body)} do
      {:ok, parsed}
    else
      {:http_request, {:error, e}} ->
        log_fetch_error(vendor_name, :http_fetch_error, url, message: HTTPoison.Error.message(e))

      {:response_success, %{status_code: status_code}} ->
        log_fetch_error(vendor_name, :bad_response_code, url, status_code: status_code)

      {:parse, _} ->
        log_fetch_error(vendor_name, :parse_error, url)

      _ ->
        log_fetch_error(vendor_name, :error, url)
    end
  end

  defp log_fetch_error(vendor_name, error, url, data \\ []) do
    Logster.warning(["#{vendor_name}_fetch_error", url: url, error: error] ++ data)
    :error
  end
end
