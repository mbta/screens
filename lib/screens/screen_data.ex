defmodule Screens.ScreenData do
  @moduledoc false

  alias Screens.Alerts.Alert
  alias Screens.Departures.Departure
  alias Screens.NearbyConnections

  @version 1

  def by_stop_id(stop_id) do
    # If we are unable to fetch alerts:
    # - inline_alerts will be an empty list
    # - global_alert will be nil
    #
    # We do this because we still want to return an API response with departures,
    # even if the other API requests fail.
    {inline_alerts, global_alert} = Alert.by_stop_id(stop_id)

    # If we are unable to fetch departures, we want to show an error message on the screen.
    departures =
      case Departure.by_stop_id(stop_id) do
        {:ok, result} ->
          {:ok, Departure.associate_alerts_with_departures(result, inline_alerts)}

        :error ->
          :error
      end

    {%{stop_name: stop_name}, nearby_connections} = NearbyConnections.by_stop_id(stop_id)

    case departures do
      {:ok, departures} ->
        %{
          version: @version,
          success: true,
          current_time: format_current_time(DateTime.utc_now()),
          stop_name: stop_name,
          stop_id: stop_id,
          departures: format_departure_rows(departures),
          global_alert: format_global_alert(global_alert),
          nearby_connections: nearby_connections
        }

      :error ->
        %{
          version: @version,
          success: false
        }
    end
  end

  defp format_current_time(t) do
    t |> DateTime.truncate(:second) |> DateTime.to_iso8601()
  end

  defp format_departure_rows(departures) do
    Enum.map(departures, &Departure.to_map/1)
  end

  def format_global_alert(alert) do
    Alert.to_map(alert)
  end
end
