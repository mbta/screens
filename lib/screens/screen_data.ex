defmodule Screens.ScreenData do
  @moduledoc false

  def by_stop_id(stop_id) do
    departures = Screens.Departures.Departure.by_stop_id(stop_id)
    alerts = Screens.Alerts.Alert.by_stop_id(stop_id)
    departures_alerts = Screens.Alerts.Alert.associate_alerts_with_departures(alerts, departures)

    %{
      current_time: DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601(),
      stop_name: extract_stop_name_from_departures(departures),
      departure_rows: format_departure_rows(departures),
      alerts: format_alerts(alerts),
      departures_alerts: departures_alerts,
      stop_id: stop_id
    }
  end

  defp extract_stop_name_from_departures(departures) do
    departures
    |> Enum.map(& &1.stop_name)
    |> Enum.reject(&is_nil/1)
    |> List.first()
  end

  defp format_departure_rows(departures) do
    departures
    |> Enum.filter(& &1.realtime)
    |> Enum.map(&Screens.Departures.Departure.to_map/1)
  end

  defp format_alerts(alerts) do
    Enum.map(alerts, &Screens.Alerts.Alert.to_map/1)
  end
end
