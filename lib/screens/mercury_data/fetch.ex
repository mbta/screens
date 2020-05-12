defmodule Screens.MercuryData.Fetch do
  @moduledoc false

  import Screens.VendorData.Fetch, only: [make_and_parse_request: 4]

  @api_url_base "https://cms.mercuryinnovation.com.au/ExtApi/devices"

  def fetch_data do
    headers = [{"apikey", Application.get_env(:screens, :mercury_api_key)}]

    case make_and_parse_request(@api_url_base, headers, &Jason.decode/1, :mercury) do
      {:ok, parsed} -> {:ok, Enum.map(parsed, &fetch_relevant_fields/1)}
      :error -> :error
    end
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
