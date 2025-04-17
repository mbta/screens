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

    @type t :: %__MODULE__{
            elevator: Elevator.t() | nil,
            facility: Facility.t(),
            periods: [Alert.active_period()]
          }

    @enforce_keys ~w[elevator facility periods]a
    defstruct @enforce_keys
  end

  require Logger
  alias Screens.Alerts.Alert
  alias Screens.Elevator
  alias Screens.Facilities.Facility
  alias Screens.Report
  alias Screens.RoutePatterns.RoutePattern
  alias Screens.Routes.Route
  alias Screens.Stops.Stop
  alias Screens.Util
  alias Screens.V2.WidgetInstance
  alias Screens.V2.WidgetInstance.Elevator.Closure, as: WidgetClosure
  alias Screens.V2.WidgetInstance.{ElevatorAlternatePath, ElevatorClosures, Footer, NormalHeader}
  alias Screens.V2.WidgetInstance.Serializer.RoutePill
  alias ScreensConfig.Screen
  alias ScreensConfig.Screen.Elevator, as: ElevatorConfig

  import Screens.Inject

  @alert injected(Alert)
  @elevator injected(Elevator)
  @facility injected(Facility)
  @route injected(Route)
  @route_pattern injected(RoutePattern)

  @active_summary_fallback {:other, "Visit mbta.com/elevators for more info"}
  @upcoming_summaries %{
    in_station: "An accessible route will be available.",
    shuttle: "An accessible route will be available via shuttle bus."
  }

  @spec elevator_status_instances(Screen.t(), DateTime.t()) :: list(WidgetInstance.t())
  def elevator_status_instances(
        %Screen{app_params: %ElevatorConfig{elevator_id: elevator_id} = app_params} = config,
        now
      ) do
    {:ok, alerts} = @alert.fetch(activities: [:using_wheelchair], include_all?: true)
    {active, upcoming} = Enum.split_with(alerts, &Alert.happening_now?/1)
    active_closures = Enum.flat_map(active, &elevator_closure/1)
    at_this_elevator? = fn %Closure{facility: %Facility{id: id}} -> id == elevator_id end

    case Enum.find(active_closures, at_this_elevator?) do
      nil ->
        {:ok, screen_facility} = @facility.fetch_by_id(elevator_id)

        relevant_closures =
          Enum.filter(active_closures, &relevant_closure?(&1, screen_facility, active_closures))

        upcoming_closures =
          upcoming |> Enum.flat_map(&elevator_closure/1) |> Enum.filter(at_this_elevator?)

        footer =
          if Enum.empty?(relevant_closures) and Enum.empty?(upcoming_closures),
            do: [],
            else: [%Footer{screen: config}]

        [
          elevator_closures(
            active_closures,
            relevant_closures,
            upcoming_closures,
            app_params,
            screen_facility,
            now
          ),
          header_instances(config, now)
          | footer
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

  defp header_instances(
         %Screen{app_params: %ElevatorConfig{elevator_id: elevator_id}} = config,
         now,
         variant \\ nil
       ) do
    %NormalHeader{text: "Elevator #{elevator_id}", screen: config, time: now, variant: variant}
  end

  defp elevator_closure(%Alert{
         id: id,
         active_period: active_periods,
         effect: :elevator_closure,
         informed_entities: entities
       }) do
    # We expect there is a 1:1 relationship between `elevator_closure` alerts and individual
    # out-of-service elevators. Log a warning if our assumptions don't hold.
    facilities = entities |> Enum.map(& &1.facility) |> Enum.reject(&is_nil/1) |> Enum.uniq()

    case facilities do
      [] ->
        []

      [%Facility{id: id} = facility] ->
        [%Closure{elevator: @elevator.get(id), facility: facility, periods: active_periods}]

      _multiple ->
        Report.warning("elevator_closure_affects_multiple", alert_id: id)
        []
    end
  end

  defp elevator_closure(_alert), do: []

  defp elevator_closures(
         active_closures,
         relevant_closures,
         upcoming_closures,
         app_params,
         %Facility{stop: %Stop{id: screen_station_id}} = screen_facility,
         now
       ) do
    %ElevatorClosures{
      app_params: app_params,
      now: now,
      station_id: screen_station_id,
      stations_with_closures:
        build_stations_with_closures(active_closures, relevant_closures, screen_facility),
      upcoming_closure: build_upcoming_closure(upcoming_closures)
    }
  end

  defp build_stations_with_closures([] = _active_closures, _, _), do: :no_closures
  defp build_stations_with_closures(_, [] = _relevant_closures, _), do: :nearby_redundancy

  defp build_stations_with_closures(active_closures, relevant_closures, screen_facility) do
    station_route_pills = fetch_station_route_pills(relevant_closures)
    downstream_facility_ids = fetch_downstream_facility_ids(relevant_closures, screen_facility)

    relevant_closures
    |> log_station_closures(screen_facility)
    |> Enum.group_by(& &1.facility.stop)
    |> Enum.map(fn {%Stop{id: station_id, name: station_name}, station_closures} ->
      %ElevatorClosures.Station{
        id: station_id,
        name: station_name,
        route_icons:
          station_route_pills
          |> Map.fetch!(station_id)
          |> Enum.map(&RoutePill.serialize_icon/1),
        closures:
          Enum.map(
            station_closures,
            fn %Closure{facility: %Facility{id: id, short_name: name}} ->
              %WidgetClosure{id: id, name: name}
            end
          ),
        summary:
          active_summary(
            station_closures,
            screen_facility,
            active_closures,
            downstream_facility_ids
          )
      }
    end)
  end

  defp fetch_station_route_pills(closures) do
    closures
    |> Enum.map(& &1.facility.stop.id)
    |> Enum.uniq()
    |> Map.new(fn station_id -> {station_id, fetch_route_pills(station_id)} end)
  end

  defp fetch_route_pills(stop_id) do
    case @route.fetch(%{stop_id: stop_id}) do
      {:ok, routes} -> routes |> Enum.map(&Route.icon/1) |> Enum.uniq()
      # Show no route pills instead of crashing the screen
      :error -> []
    end
  end

  @empty_set MapSet.new()

  # Given a list of closures and the elevator a screen is located at, determines which closures
  # could be considered "downstream" of the screen. An elevator is "downstream" when it forms
  # part of an accessible journey from the screen's station to the elevator's station, including
  # exiting that station. For example: if traveling from station A to station B would place a
  # rider on the Southbound platform of station B, and elevator X serves (only) the Northbound
  # platform of station B, then elevator X is not "downstream" of station A.
  #
  # Since the sole purpose of this logic is determining whether it's appropriate to display the
  # hand-authored "downstream" exiting summary for an elevator, and since in practice we cannot
  # be 100% accurate without a trip planner, we err on the side of *not* classifying an elevator
  # as "downstream" (in particular, we only do so when screen and elevator are found on the same
  # canonical route pattern).
  @spec fetch_downstream_facility_ids([Closure.t()], Facility.t()) :: MapSet.t(Facility.id())
  defp fetch_downstream_facility_ids(closures, %Facility{stop: %Stop{id: screen_station_id}}) do
    stop_facility_ids = stop_facility_ids(closures)

    case @route_pattern.fetch(%{canonical?: true, stop_ids: Map.keys(stop_facility_ids)}) do
      {:ok, patterns} -> downstream_facility_ids(patterns, stop_facility_ids, screen_station_id)
      # Acceptable: will show the fallback summary
      :error -> @empty_set
    end
  end

  @typep stop_facility_ids :: %{Stop.id() => MapSet.t(Facility.id())}

  @spec stop_facility_ids([Closure.t()]) :: stop_facility_ids()
  defp stop_facility_ids(closures) do
    closures
    |> Enum.reduce(%{}, fn %Closure{facility: %Facility{id: facility_id} = facility}, acc ->
      facility
      |> Facility.served_stop_ids()
      |> Enum.reduce(acc, fn stop_id, acc ->
        Map.update(acc, stop_id, MapSet.new([facility_id]), &MapSet.put(&1, facility_id))
      end)
    end)
  end

  @spec downstream_facility_ids([RoutePattern.t()], stop_facility_ids(), Stop.id()) ::
          MapSet.t(Facility.id())
  defp downstream_facility_ids(route_patterns, stop_facility_ids, screen_station_id) do
    route_patterns
    |> Enum.map(fn %RoutePattern{stops: stops} ->
      # `:unseen` indicates we have not seen the screen's station on this pattern. If we see it,
      # later stops are "downstream", so include their facilities in the result. If we never see
      # it, the acc remains `:unseen` and we discard this.
      Enum.reduce(stops, :unseen, fn
        %Stop{parent_station: %Stop{id: ^screen_station_id}}, :unseen ->
          @empty_set

        _other, :unseen ->
          :unseen

        %Stop{id: stop_id}, %MapSet{} = downstream_facility_ids ->
          stop_facility_ids
          |> Map.get(stop_id, @empty_set)
          |> MapSet.union(downstream_facility_ids)
      end)
    end)
    |> Enum.reject(&(&1 == :unseen))
    |> Enum.reduce(@empty_set, &MapSet.union(&1, &2))
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
  defp log_station_closures(station_closures, %Facility{id: elevator_id}) do
    Logger.info(
      "station_closures: " <>
        "elevator_id=#{elevator_id} " <>
        "closures=#{Enum.map_join(station_closures, ",", & &1.facility.id)}"
    )

    station_closures
  end

  # Elevators at the screen's station are always relevant.
  defp relevant_closure?(
         %Closure{facility: %Facility{stop: %Stop{id: screen_station_id}}},
         %Facility{stop: %Stop{id: screen_station_id}},
         _closures
       ),
       do: true

  # Elevators with nearby redundancy are only relevant if any of their alternates are also closed.
  defp relevant_closure?(
         %Closure{elevator: %Elevator{alternate_ids: alternate_ids, exiting_redundancy: :nearby}},
         _screen_facility,
         closures
       ) do
    Enum.any?(closures, fn %Closure{facility: %Facility{id: id}} -> id in alternate_ids end)
  end

  # Elevators with other kinds of exiting redundancy, or where we don't have redundancy data, are
  # always relevant.
  defp relevant_closure?(_closure, _screen_facility, _closures), do: true

  defp active_summary(
         [
           %Closure{
             elevator: %Elevator{
               alternate_ids: alternate_ids,
               exiting_redundancy: redundancy,
               exiting_summary: summary
             },
             facility: %Facility{id: facility_id}
           }
         ],
         %Facility{id: screen_facility_id},
         closures,
         downstream_facility_ids
       ) do
    cond do
      Enum.any?(closures, fn %Closure{facility: %Facility{id: id}} -> id in alternate_ids end) ->
        # If any of a closed elevator's alternates are also closed, the normal summary may not be
        # applicable.
        @active_summary_fallback

      redundancy in ~w[nearby in_station]a and screen_facility_id in alternate_ids ->
        {:inside, "This is the backup elevator"}

      redundancy in ~w[nearby in_station]a ->
        {:inside, summary}

      facility_id in downstream_facility_ids ->
        {:other, summary}

      true ->
        @active_summary_fallback
    end
  end

  # Use the fallback when there are multiple closures at the same station or we have no redundancy
  # data for an elevator.
  defp active_summary(_other, _screen_facility, _closures, _patterns),
    do: @active_summary_fallback

  # `nil` indicates the specially-formatted fallback summary for upcoming closures.
  defp upcoming_summary(%Closure{elevator: nil}), do: nil

  defp upcoming_summary(%Closure{elevator: %Elevator{entering_redundancy: redundancy}}) do
    Map.get(@upcoming_summaries, redundancy, nil)
  end
end
