defmodule Screens.V2.CandidateGenerator.Elevator.Closures do
  @moduledoc """
  Generates the standard widgets for elevator screens: `ElevatorAlternatePath` when the screen's
  elevator is closed, otherwise `ElevatorClosures`. Includes the header and footer, as these have
  different variants depending on the "main" widget.
  """

  defmodule Closure do
    @moduledoc false
    # Internal struct used while generating widgets. Represents a single elevator which is closed.

    alias Screens.Alerts.Alert
    alias Screens.Elevator
    alias Screens.Facilities.Facility
    alias Screens.Stops.Stop

    @type t :: %__MODULE__{
            id: Facility.id(),
            name: String.t(),
            station_id: Stop.id(),
            periods: [Alert.active_period()],
            elevator: Elevator.t() | nil
          }

    @enforce_keys ~w[id name station_id periods elevator]a
    defstruct @enforce_keys
  end

  require Logger
  alias Screens.Alerts.{Alert, InformedEntity}
  alias Screens.Elevator
  alias Screens.Facilities.Facility
  alias Screens.Report
  alias Screens.Routes.Route
  alias Screens.Stops.Stop
  alias Screens.Util
  alias Screens.V2.WidgetInstance
  alias Screens.V2.WidgetInstance.Elevator.Closure, as: WidgetClosure
  alias Screens.V2.WidgetInstance.{ElevatorAlternatePath, ElevatorClosures, Footer, NormalHeader}
  alias Screens.V2.WidgetInstance.Serializer.RoutePill
  alias ScreensConfig.Screen
  alias ScreensConfig.V2.Elevator, as: ElevatorConfig

  import Screens.Inject

  @alert injected(Alert)
  @elevator injected(Elevator)
  @facility injected(Facility)
  @route injected(Route)
  @stop injected(Stop)

  @active_summary_fallback "Visit mbta.com/elevators for more info"
  @upcoming_summaries %{
    in_station: "An accessible route will be available.",
    shuttle: "An accessible route will be available via shuttle bus."
  }

  @spec elevator_status_instances(Screen.t(), DateTime.t()) :: list(WidgetInstance.t())
  def elevator_status_instances(
        %Screen{app_params: %ElevatorConfig{elevator_id: elevator_id} = app_params} = config,
        now
      ) do
    {:ok, alerts} = @alert.fetch_elevator_alerts_with_facilities()
    {active, upcoming} = Enum.split_with(alerts, &Alert.happening_now?/1)
    active_closures = Enum.flat_map(active, &elevator_closure/1)
    at_this_elevator? = fn %Closure{id: id} -> id == elevator_id end

    {:ok, %Stop{id: stop_id}} = @facility.fetch_stop_for_facility(elevator_id)

    relevant_closures =
      active_closures |> Enum.filter(&relevant_closure?(&1, stop_id, active_closures))

    case Enum.find(active_closures, at_this_elevator?) do
      nil ->
        upcoming_closures =
          upcoming |> Enum.flat_map(&elevator_closure/1) |> Enum.filter(at_this_elevator?)

        [
          elevator_closures(
            relevant_closures,
            active_closures,
            upcoming_closures,
            app_params,
            now,
            stop_id
          )
          | header_footer_instances(
              config,
              now,
              nil,
              relevant_closures
            )
        ]

      _closure ->
        [
          %ElevatorAlternatePath{app_params: app_params}
          | header_footer_instances(config, now, :closed)
        ]
    end
  end

  defp header_footer_instances(
         %Screen{app_params: %ElevatorConfig{elevator_id: elevator_id}} = config,
         now,
         variant
       ) do
    [
      %NormalHeader{text: "Elevator #{elevator_id}", screen: config, time: now, variant: variant},
      %Footer{screen: config, variant: variant}
    ]
  end

  defp header_footer_instances(
         %Screen{app_params: %ElevatorConfig{elevator_id: elevator_id}} = config,
         now,
         variant,
         closures
       ) do
    case Enum.any?(closures) do
      true ->
        [
          %NormalHeader{
            text: "Elevator #{elevator_id}",
            screen: config,
            time: now,
            variant: variant
          },
          %Footer{screen: config, variant: variant}
        ]

      false ->
        [
          %NormalHeader{
            text: "Elevator #{elevator_id}",
            screen: config,
            time: now,
            variant: variant
          }
        ]
    end
  end

  defp elevator_closure(%Alert{
         id: id,
         active_period: active_periods,
         effect: :elevator_closure,
         informed_entities: entities
       }) do
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
        [
          %Closure{
            id: id,
            name: name,
            station_id: station_id,
            periods: active_periods,
            elevator: @elevator.get(id)
          }
        ]

      _multiple ->
        Report.warning("elevator_closure_affects_multiple", alert_id: id)
        []
    end
  end

  defp elevator_closure(_alert), do: []

  defp elevator_closures(
         [],
         _active_closures,
         upcoming_closures,
         %ElevatorConfig{elevator_id: _elevator_id} = app_params,
         now,
         stop_id
       ) do
    %ElevatorClosures{
      app_params: app_params,
      now: now,
      station_id: stop_id,
      stations_with_closures: :no_closures,
      upcoming_closure: build_upcoming_closure(upcoming_closures)
    }
  end

  defp elevator_closures(
         relevant_closures,
         active_closures,
         upcoming_closures,
         %ElevatorConfig{elevator_id: elevator_id} = app_params,
         now,
         stop_id
       ) do
    {:ok, station_names} = @stop.fetch_parent_station_name_map()
    station_route_pills = fetch_station_route_pills(active_closures, stop_id)

    %ElevatorClosures{
      app_params: app_params,
      now: now,
      station_id: stop_id,
      stations_with_closures:
        build_stations_with_closures(
          relevant_closures,
          active_closures,
          station_names,
          station_route_pills,
          elevator_id
        ),
      upcoming_closure: build_upcoming_closure(upcoming_closures)
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

  defp build_stations_with_closures(
         relevant_closures,
         active_closures,
         station_names,
         station_route_pills,
         elevator_id
       ) do
    relevant_closures
    |> log_station_closures(elevator_id)
    |> Enum.group_by(& &1.station_id)
    |> Enum.map(fn {station_id, station_closures} ->
      %ElevatorClosures.Station{
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
        summary: active_summary(station_closures, active_closures)
      }
    end)
  end

  defp build_upcoming_closure([]), do: nil

  defp build_upcoming_closure([closure | _] = closures) do
    next_date_period =
      closures
      |> Enum.filter(fn
        %Closure{elevator: %Elevator{entering_redundancy: :nearby}} -> false
        _other -> true
      end)
      |> Enum.flat_map(& &1.periods)
      |> Enum.map(fn {start_dt, end_dt} ->
        {Util.service_date(start_dt), if(end_dt, do: Util.service_date(end_dt))}
      end)
      |> Enum.sort_by(fn {start, _end} -> start end, &(Date.compare(&1, &2) in [:lt, :eq]))
      |> List.first()

    if is_nil(next_date_period),
      do: nil,
      else: %ElevatorClosures.Upcoming{
        period: next_date_period,
        summary: upcoming_summary(closure)
      }
  end

  # https://app.asana.com/0/1185117109217413/1209274790976901
  # Checking if all screens have the same elevator closure ids or not
  defp log_station_closures(station_closures, elevator_id) do
    Logger.info(
      "station_closures: " <>
        "elevator_id=#{elevator_id} " <>
        "closures=#{Enum.map_join(station_closures, ",", & &1.id)}"
    )

    station_closures
  end

  # If we couldn't find alternate/redundancy data for an elevator, assume it's relevant.
  defp relevant_closure?(%Closure{elevator: nil}, _home_station_id, _closures), do: true

  # Elevators at the home station ID are always relevant.
  defp relevant_closure?(%Closure{station_id: station_id}, station_id, _closures), do: true

  # If any of a closed elevator's alternates are also closed, it's always relevant.
  defp relevant_closure?(
         %Closure{
           elevator: %Elevator{alternate_ids: alternate_ids, exiting_redundancy: redundancy}
         },
         _home_station_id,
         closures
       ) do
    Enum.any?(closures, fn %Closure{id: id} -> id in alternate_ids end) or redundancy != :nearby
  end

  defp active_summary(
         [
           %Closure{
             elevator: %Elevator{alternate_ids: alternate_ids, exiting_redundancy: redundancy}
           }
         ],
         closures
       ) do
    # If any of a closed elevator's alternates are also closed, the normal summary may not be
    # applicable.
    if Enum.any?(closures, fn %Closure{id: id} -> id in alternate_ids end) do
      @active_summary_fallback
    else
      case redundancy do
        # `nil` indicates the specially-formatted in-station summary text for active closures.
        type when type in ~w[nearby in_station]a -> nil
        {:other, summary} -> summary
      end
    end
  end

  # Use the fallback when there are multiple closures at the same station or we have no redundancy
  # data for an elevator.
  defp active_summary(_other, _all_closures), do: @active_summary_fallback

  # `nil` indicates the specially-formatted fallback summary for upcoming closures.
  defp upcoming_summary(%Closure{elevator: nil}), do: nil

  defp upcoming_summary(%Closure{elevator: %Elevator{entering_redundancy: redundancy}}) do
    Map.get(@upcoming_summaries, redundancy, nil)
  end
end
