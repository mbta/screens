defmodule Screens.BusScreenData do
  @moduledoc false
  require Logger

  alias Screens.Alerts.Alert
  alias Screens.Departures.Departure
  alias Screens.LogScreenData
  alias Screens.NearbyConnections

  def by_stop_id_with_override_and_version(stop_id, screen_id, client_version, is_screen) do
    if Screens.Override.State.disabled?(String.to_integer(screen_id)) do
      LogScreenData.log_api_response(screen_id, client_version, is_screen, %{
        force_reload: false,
        success: false
      })
    else
      LogScreenData.log_api_response(
        screen_id,
        client_version,
        is_screen,
        by_stop_id_with_version(stop_id, client_version, screen_id, is_screen)
      )
    end
  end

  defp by_stop_id_with_version(stop_id, client_version, screen_id, is_screen) do
    api_version = Application.get_env(:screens, :api_version)

    if api_version == client_version do
      by_stop_id(stop_id, screen_id, is_screen)
    else
      %{force_reload: true}
    end
  end

  defp by_stop_id(stop_id, screen_id, is_screen) do
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

    nearby_connections_data = NearbyConnections.by_stop_id(stop_id)

    nearby_connections =
      case nearby_connections_data do
        {:ok, {_, nearby_connections}} -> nearby_connections
        _ -> []
      end

    stop_name = extract_stop_name(nearby_connections_data, departures)

    service_level = Screens.Override.State.bus_service()

    _ = LogScreenData.log_departures(screen_id, is_screen, departures)

    case departures do
      {:ok, departures} ->
        %{
          force_reload: false,
          success: true,
          current_time: Screens.Util.format_time(DateTime.utc_now()),
          stop_name: stop_name,
          stop_id: stop_id,
          departures: format_departure_rows(departures),
          global_alert: format_global_alert(global_alert),
          nearby_connections: nearby_connections,
          service_level: service_level
        }

      :error ->
        %{
          force_reload: false,
          success: false
        }
    end
  end

  defp extract_stop_name({:ok, {%{stop_name: stop_name}, _}}, _) do
    stop_name
  end

  defp extract_stop_name(_, {:ok, [departure | _]}) do
    departure.stop_name
  end

  defp extract_stop_name(_, _) do
    nil
  end

  defp format_departure_rows(departures) do
    Enum.map(departures, &Departure.to_map/1)
  end

  def format_global_alert(alert) do
    Alert.to_map(alert)
  end
end
