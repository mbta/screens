defmodule Screens.V2.CandidateGenerator.Elevator.Closures do
  @moduledoc """
  Generates the standard widgets for elevator screens: `CurrentElevatorClosed` when the screen's
  elevator is closed, otherwise `ElevatorClosuresList`. Includes the header and footer, as these
  have different variants depending on the "main" widget.
  """

  defmodule Closure do
    @moduledoc false
    # Internal struct used while generating widgets. Represents a single elevator which is closed.

    alias Screens.Elevator
    alias Screens.Facilities.Facility
    alias Screens.Stops.Stop

    @type t :: %__MODULE__{
            id: Facility.id(),
            name: String.t(),
            station_id: Stop.id(),
            elevator: Elevator.t() | nil
          }

    @enforce_keys ~w[id name station_id elevator]a
    defstruct @enforce_keys
  end

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

  alias Screens.V2.WidgetInstance.Elevator.Closure, as: WidgetClosure
  alias Screens.V2.WidgetInstance.Serializer.RoutePill
  alias ScreensConfig.Screen
  alias ScreensConfig.V2.Elevator, as: ElevatorConfig

  import Screens.Inject

  @alert injected(Alert)
  @elevator injected(Elevator)
  @facility injected(Facility)
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
    closures = Enum.flat_map(alerts, &elevator_closure/1)

    case Enum.find(closures, fn %Closure{id: id} -> id == elevator_id end) do
      nil ->
        [header_instance, elevator_closures_list(closures, app_params), footer_instance]

      _closure ->
        [
          %NormalHeader{header_instance | variant: :closed},
          %CurrentElevatorClosed{app_params: app_params},
          %Footer{footer_instance | variant: :closed}
        ]
    end
  end

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
        [%Closure{id: id, name: name, station_id: station_id, elevator: @elevator.get(id)}]

      _multiple ->
        Log.warning("elevator_closure_affects_multiple", alert_id: id)
        []
    end
  end

  defp elevator_closure(_alert), do: []

  defp elevator_closures_list(
         closures,
         %ElevatorConfig{elevator_id: elevator_id} = app_params
       ) do
    {:ok, %Stop{id: stop_id}} = @facility.fetch_stop_for_facility(elevator_id)
    {:ok, station_names} = @stop.fetch_parent_station_name_map()
    station_route_pills = fetch_station_route_pills(closures, stop_id)

    %ElevatorClosuresList{
      app_params: app_params,
      station_id: stop_id,
      stations_with_closures:
        build_stations_with_closures(closures, stop_id, station_names, station_route_pills)
    }
  end

  defp fetch_station_route_pills(closures, home_station_id) do
    closures
    |> Enum.map(& &1.station_id)
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

  defp build_stations_with_closures(closures, home_station_id, station_names, station_route_pills) do
    closures
    |> Enum.filter(&relevant_closure?(&1, home_station_id, closures))
    |> Enum.group_by(& &1.station_id)
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
            fn %Closure{id: id, name: name} -> %WidgetClosure{id: id, name: name} end
          ),
        summary: backup_route_summary(station_closures, closures)
      }
    end)
  end

  # If we couldn't find alternate/redundancy data for an elevator, assume it's relevant.
  defp relevant_closure?(%Closure{elevator: nil}, _home_station_id, _closures), do: true

  # Elevators at the home station ID are always relevant.
  defp relevant_closure?(%Closure{station_id: station_id}, station_id, _closures), do: true

  # If any of a closed elevator's alternates are also closed, it's always relevant.
  defp relevant_closure?(
         %Closure{elevator: %Elevator{alternate_ids: alternate_ids, redundancy: redundancy}},
         _home_station_id,
         closures
       ) do
    Enum.any?(closures, fn %Closure{id: id} -> id in alternate_ids end) or redundancy != :nearby
  end

  defp backup_route_summary(
         [%Closure{elevator: %Elevator{alternate_ids: alternate_ids, redundancy: redundancy}}],
         closures
       ) do
    # If any of a closed elevator's alternates are also closed, the normal summary may not be
    # applicable.
    if Enum.any?(closures, fn %Closure{id: id} -> id in alternate_ids end) do
      @fallback_summary
    else
      case redundancy do
        type when type in ~w[nearby in_station]a -> nil
        {:other, summary} -> summary
      end
    end
  end

  # Use the fallback when there are multiple closures at the same station or we have no redundancy
  # data for an elevator.
  defp backup_route_summary(_other, _all_closures), do: @fallback_summary
end
