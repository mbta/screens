defmodule Screens.DeviceMonitor.Mercury do
  @moduledoc false

  @behaviour Screens.DeviceMonitor.Vendor

  alias Screens.DeviceMonitor.Fetch

  @api_url_base "https://api.nexus.mercuryinnovation.com.au/API/mbta"
  # use `mercury_v2` for compatibility with existing reports; there were previously two distinct
  # Mercury APIs
  @vendor_name :mercury_v2

  @impl true
  def log(log_range) do
    Screens.DeviceMonitor.Logger.log_data(
      fn -> fetch(log_range) end,
      @vendor_name,
      "MERCURY_API_KEY"
    )
  end

  defp fetch(log_range) do
    headers = [{"apiKey", get_api_key()}]

    with {:ok, parsed} <-
           Fetch.make_and_parse_request(
             @api_url_base <> "/devices",
             headers,
             &Jason.decode/1,
             @vendor_name
           ) do
      prod_screens =
        Enum.filter(parsed, &match?(%{"stop" => %{"agency_id" => "mbta_prod"}}, &1))

      button_press_event_counts = fetch_button_press_events(prod_screens, log_range)

      {:ok,
       Enum.map(
         prod_screens,
         &fetch_device_info(&1, Map.get(button_press_event_counts, &1["device_id"], 0))
       )}
    end
  end

  defp fetch_device_info(device, num_button_presses) do
    device_id = device["device_id"]
    headers = [{"apiKey", get_api_key()}]

    info =
      case Fetch.make_and_parse_request(
             @api_url_base <> "/devices/#{device_id}",
             headers,
             &Jason.decode/1,
             @vendor_name
           ) do
        {:ok, parsed} -> fetch_relevant_fields(parsed)
        :error -> %{device_id: device_id, state: :error}
      end

    Map.put(info, :button_presses, num_button_presses)
  end

  defp fetch_relevant_fields(device) do
    %{
      "device_id" => device_id,
      "screens" => [screen],
      "battery_level" => battery,
      "stop" => %{"stop_id" => stop_id}
    } = device

    screen_fields = fetch_relevant_screen_fields(screen)

    Map.merge(screen_fields, %{device_id: device_id, stop_id: stop_id, battery: battery})
  end

  defp fetch_relevant_screen_fields(status) do
    %{
      "latest_logs" => %{
        "GSMStatus" => %{"rssi" => signal_strength},
        "status" => %{"internal_temp" => temperature, "battery_reading" => battery_voltage},
        "GSMBoot" => %{"serial" => connectivity_used},
        "boot" => %{"reset_cause" => connect_reason}
      },
      "State" => state,
      "Options" => %{"Name" => name},
      "last_heartbeat" => last_heartbeat
    } = status

    %{
      state: state,
      name: name,
      battery_voltage: battery_voltage,
      connect_reason: connect_reason,
      connectivity_used: connectivity_used,
      last_heartbeat: last_heartbeat,
      signal_strength: signal_strength,
      temperature: temperature
    }
  end

  defp fetch_button_press_events(devices, {from_dt, to_dt}) do
    from_unix = DateTime.to_unix(from_dt)
    to_unix = DateTime.to_unix(to_dt)
    device_ids = Enum.map_join(devices, "-", & &1["device_id"])

    case Fetch.make_and_parse_request(
           @api_url_base <> "/allEvents/#{device_ids}/#{from_unix}/#{to_unix}",
           [{"apiKey", get_api_key()}],
           &Jason.decode/1,
           @vendor_name
         ) do
      {:ok, parsed} ->
        for {device_id, events_map} <- parsed, into: %{} do
          num_button_presses =
            events_map
            |> Map.values()
            |> Enum.map(&Map.get(&1, "BUTTON_PRESS", []))
            |> Enum.concat()
            |> Enum.count()

          {device_id, num_button_presses}
        end

      _ ->
        %{}
    end
  end

  defp get_api_key, do: System.fetch_env!("MERCURY_API_KEY")
end
