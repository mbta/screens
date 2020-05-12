defmodule Screens.MercuryData.Fetch do
  @moduledoc false

  require Logger

  @api_url_base "https://cms.mercuryinnovation.com.au/ExtApi/devices"

  def fetch_data do
    headers = [{"apikey", Application.get_env(:screens, :mercury_api_key)}]

    with {:http_request, {:ok, response}} <-
           {:http_request, HTTPoison.get(@api_url_base, headers)},
         {:response_success, %{status_code: 200, body: body}} <- {:response_success, response},
         {:parse, {:ok, parsed}} <- {:parse, Jason.decode(body)} do
      {:ok, Enum.map(parsed, &fetch_relevant_fields/1)}
    else
      {:http_request, {:error, e}} ->
        log_fetch_error(:http_fetch_error, %{message: HTTPoison.Error.message(e)})

      {:response_success, %{status_code: status_code}} ->
        log_fetch_error(:bad_response_code, %{status_code: status_code})

      {:parse, {:error, e}} ->
        log_fetch_error(:parse_error, %{message: Jason.DecodeError.message(e)})

      _ ->
        log_fetch_error(:error)
    end
  end

  defp log_fetch_error(e) do
    _ = Logger.info("mercury_fetch_error #{e}")
    :error
  end

  defp log_fetch_error(e, data) do
    data_str =
      data
      |> Enum.map(fn {key, value} -> "#{key}=#{value}" end)
      |> Enum.join(" ")

    _ = Logger.info("mercury_fetch_error #{e} #{data_str}")
    :error
  end

  defp fetch_relevant_fields(%{
         "State" => state,
         "Status" => status,
         "Options" => %{"Name" => name}
       }) do
    status_fields = fetch_relevant_status_fields(status)

    Map.merge(status_fields, %{
      state: state,
      name: name
    })
  end

  defp fetch_relevant_status_fields(status) do
    %{
      signal_strength: "RSSI",
      temperature: "Temperature",
      battery: "Battery",
      battery_voltage: "BatteryVoltage",
      uptime: "Uptime",
      connect_reason: "ConnectReason",
      connectivity_used: "ConnectivityUsed"
    }
    |> Enum.map(fn {name, status_key} -> {name, Map.get(status, status_key)} end)
    |> Enum.into(%{})
  end
end
