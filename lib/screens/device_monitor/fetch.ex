defmodule Screens.DeviceMonitor.Fetch do
  @moduledoc "Shared data fetching logic for device monitor modules."

  require Logger

  def make_and_parse_request(url, headers \\ [], parse_fn, vendor_name) do
    with {:http_request, {:ok, response}} <- {:http_request, HTTPoison.get(url, headers)},
         {:response_success, %{status_code: 200, body: body}} <- {:response_success, response},
         {:parse, {:ok, parsed}} <- {:parse, parse_fn.(body)} do
      {:ok, parsed}
    else
      {:http_request, {:error, e}} ->
        log_fetch_error(
          vendor_name,
          :http_fetch_error,
          %{message: HTTPoison.Error.message(e)},
          url
        )

      {:response_success, %{status_code: status_code}} ->
        log_fetch_error(vendor_name, :bad_response_code, %{status_code: status_code}, url)

      {:parse, _} ->
        log_fetch_error(vendor_name, :parse_error, url)

      _ ->
        log_fetch_error(vendor_name, :error, url)
    end
  end

  defp log_fetch_error(vendor_name, e, url) do
    Logger.info("#{vendor_name}_fetch_error url=#{url} #{e}")
    :error
  end

  defp log_fetch_error(vendor_name, e, data, url) do
    data_str = Enum.map_join(data, " ", fn {key, value} -> "#{key}=#{value}" end)
    Logger.info("#{vendor_name}_fetch_error url=#{url} #{e} #{data_str}")
    :error
  end
end
