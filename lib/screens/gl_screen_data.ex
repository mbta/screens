defmodule Screens.GLScreenData do
  @moduledoc false

  alias Screens.Alerts.Alert
  alias Screens.Departures.Departure
  alias Screens.NearbyConnections

  def by_stop_id_with_override_and_version(stop_id, screen_id, client_version) do
    %{route_id: route_id, direction_id: direction_id} =
      :screens
      |> Application.get_env(:screen_data)
      |> Map.get(screen_id)

    if Screens.Override.State.lookup(String.to_integer(screen_id)) do
      %{
        force_reload: false,
        success: false
      }
    else
      by_stop_id_with_version(stop_id, client_version, route_id, direction_id)
    end
  end

  defp by_stop_id_with_version(stop_id, client_version, route_id, direction_id) do
    api_version = Application.get_env(:screens, :api_version)

    if api_version == client_version do
      by_stop_id(stop_id, route_id, direction_id)
    else
      %{force_reload: true}
    end
  end

  defp by_stop_id(stop_id, route_id, direction_id) do
    # If we are unable to fetch alerts:
    # - inline_alerts will be an empty list
    # - global_alert will be nil
    #
    # We do this because we still want to return an API response with departures,
    # even if the other API requests fail.
    {inline_alerts, global_alert} = Alert.by_stop_id(stop_id)

    # If we are unable to fetch departures, we want to show an error message on the screen.
    departures =
      case Departure.by_stop_id(stop_id, route_id, direction_id) do
        {:ok, result} ->
          {:ok, Departure.associate_alerts_with_departures(result, inline_alerts)}

        :error ->
          :error
      end

    nearby_connections_data = NearbyConnections.by_stop_id(stop_id)

    nearby_connections =
      case nearby_connections_data do
        {:ok, {_, nearby_connections}} -> nearby_connections
        _ -> []
      end

    # Move this and make it less brittle
    {:ok, %{direction_destinations: destinations}} = Screens.Routes.Route.by_id(route_id)
    destination = Enum.at(destinations, direction_id)

    case departures do
      {:ok, departures} ->
        %{
          force_reload: false,
          success: true,
          current_time: format_current_time(DateTime.utc_now()),
          stop_name: destination,
          stop_id: stop_id,
          route_id: route_id,
          departures: format_departure_rows(departures),
          global_alert: format_global_alert(global_alert),
          nearby_connections: nearby_connections
        }

      :error ->
        %{
          force_reload: false,
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
