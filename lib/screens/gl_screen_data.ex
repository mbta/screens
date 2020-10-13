defmodule Screens.GLScreenData do
  @moduledoc false

  alias Screens.Alerts.Alert
  alias Screens.Departures.Departure
  alias Screens.LogScreenData
  alias Screens.Config.{Gl, State}

  def by_screen_id(screen_id, is_screen) do
    %Gl{
      stop_id: stop_id,
      route_id: route_id,
      direction_id: direction_id,
      headway_mode: headway_mode?,
      platform_id: platform_id,
      service_level: service_level
    } = State.app_params(screen_id)

    {line_map_data, departures} =
      get_line_map_data_and_departures(route_id, stop_id, direction_id, platform_id)

    destination = get_destination(route_id, direction_id)

    _ = LogScreenData.log_departures(screen_id, is_screen, departures)

    # If we are unable to fetch departures or destination, we want to show an error message on the screen.
    with {:ok, departures} <- departures,
         {:ok, destination} <- destination do
      {inline_alerts, global_alert} = Alert.by_route_id(route_id, stop_id)
      {psa_type, psa_url} = Screens.Psa.current_psa_for(screen_id)

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
        nearby_departures: Screens.NearbyDepartures.by_screen_id(screen_id),
        line_map: line_map_data,
        headway: Screens.Headways.by_route_id(route_id, stop_id, direction_id, service_level),
        service_level: service_level,
        is_headway_mode: headway_mode?,
        psa_type: psa_type,
        psa_url: psa_url
      }
    else
      :error ->
        %{
          force_reload: false,
          success: false
        }
    end
  end

  @typep line_map_data :: map() | nil
  @typep departures :: {:ok, list()} | :error
  @spec get_line_map_data_and_departures(String.t(), String.t(), 0 | 1, String.t()) ::
          {line_map_data(), departures()}
  defp get_line_map_data_and_departures(route_id, stop_id, direction_id, platform_id) do
    predictions =
      Screens.Predictions.Prediction.fetch(%{
        direction_id: direction_id,
        route_ids: [route_id],
        stop_ids: [stop_id]
      })

    case predictions do
      {:ok, predictions} ->
        {line_map_data, filtered_predictions} =
          Screens.LineMap.by_stop_id(platform_id, route_id, direction_id, predictions)

        departures = Departure.from_predictions(filtered_predictions)

        {line_map_data, departures}

      :error ->
        # handle case where vehicle request fails
        {nil, :error}
    end
  end

  @spec get_destination(String.t(), 0 | 1) :: {:ok, String.t()} | :error
  defp get_destination(route_id, direction_id) do
    case Screens.Routes.Route.by_id(route_id) do
      {:ok, %{direction_destinations: destinations}} -> {:ok, Enum.at(destinations, direction_id)}
      :error -> :error
    end
  end

  defp format_departure_rows(departures) do
    Enum.map(departures, &Map.from_struct/1)
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
