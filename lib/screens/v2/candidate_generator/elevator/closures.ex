defmodule Screens.V2.CandidateGenerator.Elevator.Closures do
  @moduledoc false

  alias Screens.Alerts.{Alert, InformedEntity}
  alias Screens.Elevator
  alias Screens.Facilities.Facility
  alias Screens.Log
  alias Screens.Routes.Route
  alias Screens.Stops.Stop
  alias Screens.V2.WidgetInstance

  alias Screens.V2.WidgetInstance.{
    CurrentElevatorClosed,
    ElevatorClosuresList,
    Footer,
    NormalHeader
  }

  alias Screens.V2.WidgetInstance.Elevator.Closure
  alias Screens.V2.WidgetInstance.Serializer.RoutePill
  alias ScreensConfig.Screen
  alias ScreensConfig.V2.Elevator, as: ElevatorConfig

  import Screens.Inject

  @alert injected(Alert)
  @elevator injected(Elevator)
  @facility injected(Screens.Facilities.Facility)
  @route injected(Route)
  @stop injected(Stop)

  @fallback_summary "Visit mbta.com/alerts for more info"

  @spec elevator_status_instances(Screen.t(), NormalHeader.t(), Footer.t()) ::
          list(WidgetInstance.t())
  def elevator_status_instances(
        %Screen{app_params: %ElevatorConfig{elevator_id: elevator_id} = app_params},
        header_instance,
        footer_instance
      ) do
    {:ok, alerts} = @alert.fetch_elevator_alerts_with_facilities()
    elevator_closures = Enum.flat_map(alerts, &elevator_closure/1)

    case Enum.find(
           elevator_closures,
           fn {_station_id, id, _name, _elevator} -> id == elevator_id end
         ) do
      nil ->
        [header_instance, elevator_closures_list(elevator_closures, app_params), footer_instance]

      _closure ->
        [
          %NormalHeader{header_instance | variant: :closed},
          %CurrentElevatorClosed{app_params: app_params},
          %Footer{footer_instance | variant: :closed}
        ]
    end
  end

  defp elevator_closures_list(
         elevator_closures,
         %ElevatorConfig{elevator_id: elevator_id} = app_params
       ) do
    {:ok, %Stop{id: stop_id}} = @facility.fetch_stop_for_facility(elevator_id)
    {:ok, station_names} = @stop.fetch_parent_station_name_map()
    station_routes = fetch_station_route_pills(elevator_closures, stop_id)

    %ElevatorClosuresList{
      app_params: app_params,
      station_id: stop_id,
      stations_with_closures:
        build_stations_with_closures(elevator_closures, stop_id, station_names, station_routes)
    }
  end

  @spec elevator_closure(Alert.t()) ::
          [{Stop.id(), Facility.id(), String.t(), Elevator.t() | nil}]
  defp elevator_closure(%Alert{id: id, effect: :elevator_closure, informed_entities: entities}) do
    # We expect there is a 1:1 relationship between `elevator_closure` alerts and individual
    # out-of-service elevators. Log a warning if our assumptions don't hold.
    stations_and_facilities =
      entities
      |> Enum.filter(&(InformedEntity.parent_station?(&1) and not is_nil(&1.facility)))
      |> Enum.map(fn %{facility: facility, stop: station_id} -> {station_id, facility} end)
      |> Enum.uniq()

    case stations_and_facilities do
      [] ->
        []

      [{station_id, %{id: id, name: name}}] ->
        [{station_id, id, name, @elevator.get(id)}]

      _multiple ->
        Log.warning("elevator_closure_affects_multiple", alert_id: id)
        []
    end
  end

  defp elevator_closure(_alert), do: []

  defp fetch_station_route_pills(elevator_closures, home_station_id) do
    elevator_closures
    |> Enum.map(fn {station_id, _id, _name, _elevator} -> station_id end)
    |> MapSet.new()
    |> MapSet.put(home_station_id)
    |> Map.new(fn station_id -> {station_id, fetch_route_pills(station_id)} end)
  end

  defp fetch_route_pills(stop_id) do
    case @route.fetch(%{stop_id: stop_id}) do
      {:ok, routes} -> routes |> Enum.map(&Route.icon/1) |> Enum.uniq()
      # Show no route pills instead of crashing the screen
      :error -> []
    end
  end

  defp build_stations_with_closures(
         elevator_closures,
         home_station_id,
         station_names,
         station_route_pills
       ) do
    elevator_closures
    |> Enum.filter(&relevant_closure?(&1, home_station_id, elevator_closures))
    |> Enum.group_by(fn {station_id, _id, _name, _elevator} -> station_id end)
    |> Enum.map(fn {station_id, station_closures} ->
      %ElevatorClosuresList.Station{
        id: station_id,
        name: Map.fetch!(station_names, station_id),
        route_icons:
          station_route_pills
          |> Map.fetch!(station_id)
          |> Enum.map(&RoutePill.serialize_icon/1),
        closures:
          Enum.map(
            station_closures,
            fn {_station_id, id, name, _elevator} -> %Closure{id: id, name: name} end
          ),
        summary: backup_route_summary(station_closures, elevator_closures)
      }
    end)
  end

  # If we couldn't find alternate/redundancy data for an elevator, assume it's relevant.
  defp relevant_closure?({_station_id, _id, _name, _elevator = nil}, _, _), do: true

  # Elevators at the home station ID are always relevant.
  defp relevant_closure?({station_id, _id, _name, _elevator}, station_id, _), do: true

  defp relevant_closure?(
         {_station_id, _id, _name,
          %Elevator{alternate_ids: alternate_ids, redundancy: redundancy}},
         _home_station_id,
         all_closures
       ) do
    if Enum.any?(all_closures, fn {_station_id, id, _name, _elevator} -> id in alternate_ids end) do
      # If any of a closed elevator's alternates are also closed, it's always relevant.
      true
    else
      redundancy != :nearby
    end
  end

  defp backup_route_summary([{_station_id, _id, _name, _elevator = nil}], _),
    do: @fallback_summary

  defp backup_route_summary(
         [
           {_station_id, _id, _name,
            %Elevator{alternate_ids: alternate_ids, redundancy: redundancy}}
         ],
         all_closures
       ) do
    # If any of a closed elevator's alternates are also closed, the normal summary may not be
    # applicable.
    if Enum.any?(all_closures, fn {_station_id, id, _name, _elevator} -> id in alternate_ids end) do
      @fallback_summary
    else
      case redundancy do
        type when type in ~w[nearby in_station]a -> nil
        {:other, summary} -> summary
      end
    end
  end

  defp backup_route_summary(_multiple, _all_closures), do: @fallback_summary
end
