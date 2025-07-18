defmodule Screens.DeviceMonitor.Mercury do
  @moduledoc false

  # Docs: https://mercuryinnovation.notion.site/Nexus-MBTA-API-192a7568977c8082a879f47b5adbbab1

  @behaviour Screens.DeviceMonitor.Vendor

  alias Screens.DeviceMonitor.Fetch

  @api_url_base "https://api.nexus.mercuryinnovation.com.au/API/mbta"
  # use `mercury_v2` for compatibility with existing reports; there were previously two distinct
  # Mercury APIs
  @vendor_name :mercury_v2

  @impl true
  def log(log_range) do
    Screens.DeviceMonitor.Logger.log_data(
      fn -> do_log(log_range) end,
      @vendor_name,
      "MERCURY_API_KEY"
    )
  end

  defp do_log({from_dt, to_dt}) do
    from_unix = DateTime.to_unix(from_dt)
    to_unix = DateTime.to_unix(to_dt)

    with {:ok, devices} <- fetch("/devices?verbose=true"),
         {:ok, events} <- fetch("/allEvents/#{from_unix}/#{to_unix}") do
      button_press_counts_by_device =
        for {device_id, device_events} <- events, into: %{} do
          count =
            device_events
            |> Map.values()
            |> Enum.map(&Map.get(&1, "BUTTON_PRESS", []))
            |> Enum.concat()
            |> Enum.count()

          {device_id, count}
        end

      {:ok,
       devices
       |> Enum.filter(&match?(%{"stop" => %{"agency_id" => "mbta_prod"}}, &1))
       |> Enum.map(&device_info(&1, Map.get(button_press_counts_by_device, &1["device_id"], 0)))}
    end
  end

  defp fetch(path) do
    Fetch.make_and_parse_request(
      @api_url_base <> path,
      [{"apiKey", get_api_key()}],
      # devices API sometimes takes longer to respond than the default timeout of 5 seconds
      [recv_timeout: 10_000],
      &Jason.decode/1,
      @vendor_name
    )
  end

  defp device_info(
         %{
           "device_id" => device_id,
           "battery_level" => battery,
           "screens" => [
             %{
               "last_heartbeat" => last_heartbeat,
               "latest_logs" => %{
                 "boot" => %{"reset_cause" => connect_reason},
                 "GSMBoot" => %{"serial" => connectivity_used},
                 "GSMStatus" => %{"rssi" => signal_strength},
                 "status" => %{
                   "battery_reading" => battery_voltage,
                   "internal_temp" => temperature
                 }
               },
               "Options" => %{"Name" => name},
               "State" => state
             }
           ],
           "stop" => %{"stop_id" => stop_id}
         },
         button_press_count
       ) do
    %{
      device_id: device_id,
      battery: battery,
      battery_voltage: battery_voltage,
      button_presses: button_press_count,
      connect_reason: connect_reason,
      connectivity_used: connectivity_used,
      last_heartbeat: last_heartbeat,
      name: name,
      signal_strength: signal_strength,
      state: state,
      stop_id: stop_id,
      temperature: temperature
    }
  end

  defp get_api_key, do: System.fetch_env!("MERCURY_API_KEY")
end
