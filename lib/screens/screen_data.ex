defmodule Screens.ScreenData do
  @moduledoc false

  @version 1

  def by_stop_id(stop_id) do
    {inline_alerts, global_alert} = Screens.Alerts.Alert.by_stop_id(stop_id)

    departures =
      stop_id
      |> Screens.Departures.Departure.by_stop_id()
      |> Screens.Departures.Departure.associate_alerts_with_departures(inline_alerts)

    {%{stop_name: stop_name}, nearby_connections} = Screens.NearbyConnections.by_stop_id(stop_id)

    %{
      version: @version,
      current_time: format_current_time(DateTime.utc_now()),
      stop_name: stop_name,
      stop_id: stop_id,
      departures: format_departure_rows(departures),
      global_alert: format_global_alert(global_alert),
      nearby_connections: nearby_connections
    }
  end

  defp format_current_time(t) do
    t |> DateTime.truncate(:second) |> DateTime.to_iso8601()
  end

  defp format_departure_rows(departures) do
    Enum.map(departures, &Screens.Departures.Departure.to_map/1)
  end

  def format_global_alert(alert) do
    Screens.Alerts.Alert.to_map(alert)
  end
end
