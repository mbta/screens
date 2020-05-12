defmodule Screens.MercuryData.Fetch do
  @moduledoc false

  @api_url_base "https://cms.mercuryinnovation.com.au/ExtApi/devices"

  def fetch_data do
    headers = [{"apikey", Application.get_env(:screens, :mercury_api_key)}]

    with {:ok, response} <- HTTPoison.get(@api_url_base, headers),
         %{status_code: 200, body: body} <- response,
         {:ok, parsed} <- Jason.decode(body) do
      {:ok, Enum.map(parsed, &fetch_relevant_fields/1)}
    else
      _ -> :error
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
