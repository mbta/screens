defmodule Screens.VendorData.Fetch do
  @moduledoc false

  require Logger

  def make_and_parse_request(url, headers \\ [], parse_fn, vendor_name) do
    with {:http_request, {:ok, response}} <- {:http_request, HTTPoison.get(url, headers)},
         {:response_success, %{status_code: 200, body: body}} <- {:response_success, response},
         {:parse, {:ok, parsed}} <- {:parse, parse_fn.(body)} do
      {:ok, parsed}
    else
      {:http_request, {:error, e}} ->
        log_fetch_error(vendor_name, :http_fetch_error, %{message: HTTPoison.Error.message(e)})

      {:response_success, %{status_code: status_code}} ->
        log_fetch_error(vendor_name, :bad_response_code, %{status_code: status_code})

      {:parse, _} ->
        log_fetch_error(vendor_name, :parse_error)

      _ ->
        log_fetch_error(vendor_name, :error)
    end
  end

  defp log_fetch_error(vendor_name, e) do
    _ = Logger.info("#{vendor_name}_fetch_error #{e}")
    :error
  end

  defp log_fetch_error(vendor_name, e, data) do
    data_str =
      data
      |> Enum.map(fn {key, value} -> "#{key}=#{value}" end)
      |> Enum.join(" ")

    _ = Logger.info("#{vendor_name}_fetch_error #{e} #{data_str}")
    :error
  end
end
