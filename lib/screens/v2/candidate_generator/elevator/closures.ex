defmodule Screens.V2.CandidateGenerator.Elevator.Closures do
  @moduledoc false

  require Logger

  alias Screens.Alerts.{Alert, InformedEntity}
  alias Screens.Routes.Route
  alias Screens.Stops.Stop
  alias Screens.V2.WidgetInstance.ElevatorClosures
  alias Screens.V2.WidgetInstance.Serializer.RoutePill
  alias ScreensConfig.Screen
  alias ScreensConfig.V2.Elevator

  import Screens.Inject

  @alert injected(Alert)
  @facility injected(Screens.Facilities.Facility)
  @route injected(Route)
  @stop injected(Stop)

  @spec elevator_status_instances(Screen.t()) :: list(ElevatorClosures.t())
  def elevator_status_instances(%Screen{app_params: %Elevator{elevator_id: elevator_id} = config}) do
    with {:ok, %Stop{id: stop_id}} <- @facility.fetch_stop_for_facility(elevator_id),
         {:ok, parent_station_map} <- @stop.fetch_parent_station_name_map(),
         {:ok, alerts} <- @alert.fetch_elevator_alerts_with_facilities() do
      elevator_alerts = Enum.filter(alerts, &relevant_alert?/1)
      routes_map = get_routes_map(elevator_alerts, stop_id)

      {in_station_alerts, outside_alerts} =
        split_closures_by_location(elevator_alerts, stop_id)

      [
        %ElevatorClosures{
          in_station_closures: Enum.map(in_station_alerts, &alert_to_elevator_closure/1),
          other_stations_with_closures:
            format_outside_closures(outside_alerts, parent_station_map, routes_map),
          elevator_config: config
        }
      ]
    else
      :error ->
        []

      {:error, error} ->
        Logger.error("[elevator_status_instances] #{inspect(error)}")
        []
    end
  end

  defp relevant_alert?(alert) do
    relevant_effect?(alert) and informs_one_facility?(alert)
  end

  defp relevant_effect?(alert), do: alert.effect == :elevator_closure

  defp informs_one_facility?(%Alert{informed_entities: informed_entities}) do
    Enum.all?(informed_entities, &match?(%{facility: _}, &1)) and
      informed_entities |> Enum.map(& &1.facility) |> Enum.uniq() |> Enum.count() == 1
  end

  defp get_routes_map(elevator_closures, home_parent_station_id) do
    elevator_closures
    |> get_parent_station_ids_from_entities()
    |> MapSet.new()
    |> MapSet.put(home_parent_station_id)
    |> Enum.map(fn station_id ->
      {station_id, station_id |> route_ids_serving_stop() |> routes_to_labels()}
    end)
    |> Enum.into(%{})
  end

  defp get_parent_station_ids_from_entities(closures) do
    closures
    |> Enum.flat_map(fn %Alert{informed_entities: informed_entities} ->
      informed_entities
      |> Enum.filter(&InformedEntity.parent_station?/1)
      |> Enum.map(fn %{stop: stop_id} -> stop_id end)
    end)
  end

  defp route_ids_serving_stop(stop_id) do
    case @route.fetch(%{stop_id: stop_id}) do
      {:ok, routes} -> routes
      # Show no route pills instead of crashing the screen
      :error -> []
    end
  end

  defp routes_to_labels(routes) do
    routes
    |> Enum.map(&Route.icon/1)
    |> Enum.uniq()
  end

  defp split_closures_by_location(closures, home_stop_id) do
    Enum.split_with(closures, fn %Alert{informed_entities: informed_entities} ->
      home_stop_id in Enum.map(informed_entities, & &1.stop)
    end)
  end

  defp alert_to_elevator_closure(%Alert{
         id: id,
         informed_entities: entities,
         description: description,
         header: header
       }) do
    facility = Enum.find_value(entities, fn %{facility: facility} -> facility end)

    %ElevatorClosures.Closure{
      id: id,
      elevator_name: facility.name,
      elevator_id: facility.id,
      description: description,
      header_text: header
    }
  end

  defp format_outside_closures(closures, station_id_to_name, station_id_to_routes) do
    closures
    |> Enum.group_by(&get_parent_station_id_from_informed_entities(&1.informed_entities))
    |> Enum.map(fn {parent_station_id, closures} ->
      closures_at_station = Enum.map(closures, &alert_to_elevator_closure/1)

      route_pills =
        station_id_to_routes
        |> Map.fetch!(parent_station_id)
        |> Enum.map(&RoutePill.serialize_icon/1)

      %ElevatorClosures.Station{
        id: parent_station_id,
        name: Map.fetch!(station_id_to_name, parent_station_id),
        route_icons: route_pills,
        closures: closures_at_station
      }
    end)
  end

  defp get_parent_station_id_from_informed_entities(entities) do
    entities
    |> Enum.find_value(fn
      ie -> if InformedEntity.parent_station?(ie), do: ie.stop
    end)
  end
end
