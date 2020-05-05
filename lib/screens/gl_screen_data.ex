defmodule Screens.GLScreenData do
  @moduledoc false
  require Logger

  alias Screens.Alerts.Alert
  alias Screens.Departures.Departure
  alias Screens.LogScreenData

  def by_stop_id_with_override_and_version(stop_id, screen_id, client_version, is_screen) do
    %{route_id: route_id, direction_id: direction_id, platform_id: platform_id} =
      :screens
      |> Application.get_env(:screen_data)
      |> Map.get(screen_id)

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
        by_stop_id_with_version(
          stop_id,
          client_version,
          route_id,
          direction_id,
          platform_id,
          screen_id,
          is_screen
        )
      )
    end
  end

  defp by_stop_id_with_version(
         stop_id,
         client_version,
         route_id,
         direction_id,
         platform_id,
         screen_id,
         is_screen
       ) do
    api_version = Application.get_env(:screens, :api_version)

    if api_version == client_version do
      by_stop_id(
        stop_id,
        route_id,
        direction_id,
        platform_id,
        screen_id,
        is_screen
      )
    else
      %{force_reload: true}
    end
  end

  defp by_stop_id(
         stop_id,
         route_id,
         direction_id,
         platform_id,
         screen_id,
         is_screen
       ) do
    # If we are unable to fetch alerts:
    # - inline_alerts will be an empty list
    # - global_alert will be nil
    #
    # We do this because we still want to return an API response with departures,
    # even if the other API requests fail.
    {inline_alerts, global_alert} = Alert.by_route_id(route_id, stop_id)

    predictions =
      Screens.Predictions.Prediction.fetch(%{
        stop_id: stop_id,
        route_id: route_id,
        direction_id: direction_id
      })

    {line_map_data, predictions} =
      case predictions do
        {:ok, predictions} ->
          Screens.LineMap.by_stop_id(platform_id, route_id, direction_id, predictions)

        :error ->
          # handle case where vehicle request fails
          {nil, :error}
      end

    # If we are unable to fetch departures, we want to show an error message on the screen.
    departures =
      case Departure.from_predictions(predictions) do
        {:ok, result} -> {:ok, result}
        :error -> :error
      end

    nearby_departures = Screens.NearbyDepartures.by_stop_id(stop_id)

    # Move this and make it less brittle
    {:ok, %{direction_destinations: destinations}} = Screens.Routes.Route.by_id(route_id)
    destination = Enum.at(destinations, direction_id)

    service_level = Screens.Override.State.green_line_service()

    headway_data = Screens.Headways.by_route_id(route_id, stop_id, direction_id, service_level)

    _ = LogScreenData.log_departures(screen_id, is_screen, departures)

    psa_name = Screens.Psa.current_green_line_psa()

    case departures do
      {:ok, departures} ->
        %{
          force_reload: false,
          success: true,
          current_time: Screens.Util.format_time(DateTime.utc_now()),
          stop_name: destination,
          stop_id: stop_id,
          route_id: route_id,
          departures: format_departure_rows(departures),
          global_alert: format_global_alert(global_alert),
          inline_alert: format_inline_alert(inline_alerts),
          nearby_departures: nearby_departures,
          line_map: line_map_data,
          headway: headway_data,
          service_level: service_level,
          is_headway_mode: Screens.Override.State.headway_mode?(String.to_integer(screen_id)),
          psa_name: psa_name
        }

      :error ->
        %{
          force_reload: false,
          success: false
        }
    end
  end

  defp format_departure_rows(departures) do
    Enum.map(departures, &Departure.to_map/1)
  end

  def format_global_alert(alert) do
    Alert.to_map(alert)
  end

  defp format_inline_alert([alert | _]) do
    %{severity: alert.severity}
  end

  defp format_inline_alert(_) do
    nil
  end
end
