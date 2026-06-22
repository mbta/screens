defmodule Screens.V2.RDS do
  @moduledoc """
  Real-time Destination State. Represents a "destination" a rider could reach (ordinarily or
  currently) by taking a line from a stop, and the "state" of that destination, in the form of
  departure countdowns, a headway estimate, a message that service has ended for the day, etc.

  Conceptually, screen configuration is translated into a set of "destinations", each of which is
  assigned a "state", containing all the data required to present it. These can then be translated
  into widgets by screen-specific code.
  """

  import Screens.Inject

  alias Screens.Alerts.Alert
  alias Screens.Alerts.InformedEntity
  alias Screens.Config.Cache
  alias Screens.Headways, as: Headway
  alias Screens.LastTrip.LastTrip
  alias Screens.Lines.Line
  alias Screens.Report
  alias Screens.RoutePatterns.RoutePattern
  alias Screens.Routes.Route
  alias Screens.RouteType
  alias Screens.Schedules.Schedule
  alias Screens.Stops.Stop
  alias Screens.Trips.Trip
  alias Screens.Util

  alias Screens.V2.Departure

  alias ScreensConfig.Departures
  alias ScreensConfig.Departures.{Query, Section}

  alias __MODULE__.{Countdowns, FirstTrip, Headways, NoService, ServiceEnded}

  @type state :: NoService.t() | Countdowns.t() | FirstTrip.t() | ServiceEnded.t() | Headways.t()

  @type t :: %__MODULE__{stop: Stop.t(), line: Line.t(), headsign: String.t(), state: state()}
  @enforce_keys ~w[stop line headsign state]a
  defstruct @enforce_keys

  @type section_t :: {:ok, [t()]} | :error
  @type destination_key :: {Stop.id(), Line.id(), String.t()}

  @typep destination :: {Stop.t(), Line.t(), String.t()}
  @typep scheduled_service_state :: :after | :before | :none | :within

  # These alert types eliminate service to a destination.
  @relevant_alert_effects [
    :detour,
    :dock_closure,
    :no_service,
    :shuttle,
    :snow_route,
    :station_closure,
    :stop_closure,
    :stop_move,
    :suspension
  ]

  @red_trunk [70_061..70_061, 70_063..70_084]
             |> Enum.flat_map(& &1)
             |> Enum.map(&Integer.to_string(&1))
  @last_trip_buffer_seconds 3

  defmodule NoService do
    @moduledoc """
    The state that represents when a given destination
    has no relevant live data (alerts or predictions)
    and no scheduled departures for the day.
    """
    @type t :: %__MODULE__{routes: [Route.t()], direction_id: Trip.direction() | nil}
    defstruct ~w[routes direction_id]a
  end

  defmodule Countdowns do
    @moduledoc """
    State when there is upcoming service to a destination
    and/or alerts which affect service to the destination.
    """
    @type t :: %__MODULE__{departures: [Departure.t(), ...]}
    defstruct ~w[departures]a
  end

  defmodule FirstTrip do
    @moduledoc """
    State when we are in a new service day and are
    showing the first scheduled trip of the day for a
    given destination.
    """
    @type t :: %__MODULE__{first_schedule: Schedule.t()}
    defstruct ~w[first_schedule]a
  end

  defmodule ServiceEnded do
    @moduledoc """
    State for after the end of the last scheduled departure
    or if we observe a departure that is the Last Trip of the Day
    """
    @type t :: %__MODULE__{last_schedule: Schedule.t()}
    defstruct ~w[last_schedule]a
  end

  defmodule Headways do
    @moduledoc """
    State for if we're in an active period, but we have no predictions
    and there are no alerts associated with the destination.

    Shows an every “X-Y” minutes message. 
    """
    @type t :: %__MODULE__{
            route_id: Route.id(),
            direction_name: String.t(),
            direction_id: Trip.direction(),
            range: Headway.range()
          }
    defstruct ~w[route_id direction_name direction_id range]a
  end

  @alert injected(Alert)
  @departure injected(Departure)
  @headways injected(Headway)
  @route_pattern injected(RoutePattern)
  @schedule injected(Schedule)
  @stop injected(Stop)
  @config_cache injected(Cache)
  @last_trip injected(LastTrip)

  @max_departure_minutes 120

  @doc """
  Generates destinations from departures widget configuration.

  Produces a list of destinations for each configured `Section`, in the same order the sections
  occur in the config.

  ⚠️ Enforces that every section's query contains at least one ID in `stop_ids`.
  """
  @callback get(Departures.t()) :: [section_t()]
  @callback get(Departures.t(), DateTime.t()) :: [section_t()]
  def get(%Departures{sections: sections}, now \\ DateTime.utc_now()),
    do:
      sections
      |> Task.async_stream(&from_section(&1, now), timeout: 15_000)
      |> Enum.map(fn
        {:ok, result} ->
          result

        {:exit, reason} ->
          Report.warning("rds_async_section_error", [reason])
          :error
      end)

  @spec from_section(Section.t(), DateTime.t()) :: section_t()
  defp from_section(
         %Section{query: %Query{params: %Query.Params{stop_ids: stop_ids} = params}},
         now
       )
       when stop_ids != [] do
    with params_struct <- Map.from_struct(params),
         {:ok, typical_patterns} <-
           params_struct |> Map.put(:typicality, 1) |> @route_pattern.fetch(),
         {:ok, child_stops} <- fetch_child_stops(stop_ids),
         {:ok, schedules} <- @schedule.fetch(params_struct, Util.service_date(now)),
         {:ok, alerts} <- fetch_relevant_alerts(stop_ids, now),
         {:ok, departures} <-
           params_struct |> @departure.fetch(now: now, include_scheduled_cancelled?: true) do
      case create_routes_for_section(departures, schedules, typical_patterns, params) do
        {[_ | _] = enabled_routes_for_section, _} ->
          create_section_rds(
            departures,
            schedules,
            typical_patterns,
            child_stops,
            enabled_routes_for_section,
            alerts,
            now
          )

        {[], [_ | _] = _routes_for_section} ->
          {:ok, []}

        _ ->
          Report.warning("rds_no_section_routes", params: inspect(params))
          :error
      end
    end
  end

  @spec fetch_child_stops([Stop.id()]) :: {:ok, [Stop.t()]} | :error
  defp fetch_child_stops(stop_ids) do
    with {:ok, stops} <- @stop.fetch(%{ids: stop_ids}) do
      stops_by_id = Map.new(stops, fn %Stop{id: id} = stop -> {id, stop} end)

      child_stops =
        stop_ids
        |> Enum.map(&stops_by_id[&1])
        |> Enum.flat_map(fn
          %Stop{location_type: 0} = stop -> [stop]
          %Stop{child_stops: stops} when is_list(stops) -> stops
          # stop ID in screen configuration does not exist; drop it
          nil -> []
        end)

      {:ok, child_stops}
    end
  end

  defp create_section_rds(
         departures,
         schedules,
         typical_patterns,
         child_stops,
         routes_for_section,
         alerts,
         now
       ) do
    departures_by_destination = group_by_destination(departures)
    schedules_by_destination = group_by_destination(schedules)

    destinations =
      (tuples_from_departures(departures, now) ++
         tuples_from_patterns(typical_patterns, child_stops))
      |> Enum.uniq_by(fn {stop, line, headsign} -> {stop.id, line.id, headsign} end)

    # Destinations that are affected by current alerts at the present stop ID
    impacted_destinations = informed_destinations(destinations, alerts, typical_patterns)

    section_rds =
      destinations
      |> Enum.map(fn {%Stop{id: stop_id} = stop, line, headsign} = destination ->
        key = to_destination_key(destination)

        %__MODULE__{
          stop: stop,
          line: line,
          headsign: headsign,
          state:
            destination_state(
              Map.get(departures_by_destination, key, []),
              Map.get(schedules_by_destination, key, []),
              @headways.get(stop_id, now),
              routes_for_section,
              last_trip_departed?(key, now),
              destination in impacted_destinations,
              now
            )
        }
      end)
      |> Enum.reject(&is_nil(&1.state))

    {:ok, section_rds}
  end

  @spec tuples_from_departures([Departure.t()], DateTime.t()) :: [destination()]
  defp tuples_from_departures(departures, now) do
    departures
    |> Enum.filter(&(DateTime.diff(Departure.time(&1), now, :minute) <= @max_departure_minutes))
    |> Enum.map(&departure_destination(&1))
  end

  @spec tuples_from_patterns([RoutePattern.t()], [Stop.id()]) :: [destination()]
  defp tuples_from_patterns(route_patterns, child_stops) do
    stop_ids = child_stops |> List.flatten() |> Enum.map(& &1.id) |> MapSet.new()

    Enum.flat_map(
      route_patterns,
      fn %RoutePattern{headsign: headsign, route: %Route{line: line}, stops: stops} ->
        stops
        |> Enum.drop(-1)
        |> Enum.filter(&(&1.id in stop_ids))
        |> Enum.map(fn stop -> {stop, line, headsign} end)
      end
    )
  end

  @spec destination_state(
          [Departure.t()],
          [Schedule.t()],
          Headway.range() | nil,
          [Route.t()],
          boolean(),
          boolean(),
          DateTime.t()
        ) :: state() | nil
  defp destination_state(
         departures,
         schedules,
         headways,
         routes_for_section,
         last_trip_departed?,
         impacted_by_alert?,
         now
       ) do
    {first_schedule, last_schedule} =
      schedules
      |> Enum.sort_by(&Schedule.time(&1), DateTime)
      |> then(&{List.first(&1), List.last(&1)})

    presented_departures =
      Enum.filter(departures, &presented_departure?(&1, not is_nil(headways), impacted_by_alert?))

    service_state =
      scheduled_service_state(first_schedule, last_schedule, headways, last_trip_departed?, now)

    cond do
      presented_departures != [] -> %Countdowns{departures: presented_departures}
      impacted_by_alert? -> nil
      departures == [] and service_state == :none -> %NoService{routes: routes_for_section}
      departures == [] and service_state == :after -> %ServiceEnded{last_schedule: last_schedule}
      service_state == :before -> %FirstTrip{first_schedule: first_schedule}
      not (is_nil(headways) or is_nil(first_schedule)) -> headways_state(headways, first_schedule)
      true -> nil
    end
  end

  defp presented_departure?(%Departure{prediction: prediction} = departure, headways?, alert?) do
    cond do
      is_nil(prediction) -> not headways? and not alert?
      Departure.cancelled?(departure) -> not headways?
      true -> true
    end
  end

  defp headways_state(headways, %Schedule{
         route: %Route{id: route_id} = route,
         trip: %Trip{direction_id: direction_id}
       }) do
    %Headways{
      route_id: route_id,
      direction_name: route |> Route.normalized_direction_names() |> Enum.at(direction_id),
      direction_id: direction_id,
      range: headways
    }
  end

  @spec scheduled_service_state(
          Schedule.t() | nil,
          Schedule.t() | nil,
          Headway.range() | nil,
          boolean(),
          DateTime.t()
        ) :: scheduled_service_state()
  defp scheduled_service_state(nil = _first, nil = _last, _headways, _last_departed?, _now),
    do: :none

  defp scheduled_service_state(_first, _last, _headways, true = _last_departed?, _now),
    do: :after

  defp scheduled_service_state(first_schedule, last_schedule, headways, _last_departed?, now) do
    effective_start = first_schedule |> Schedule.time() |> effective_service_time(headways)
    effective_end = last_schedule |> Schedule.time() |> effective_service_time(headways)

    cond do
      DateTime.compare(now, effective_start) == :lt -> :before
      DateTime.compare(now, effective_end) == :gt -> :after
      true -> :within
    end
  end

  defp effective_service_time(nil, _headways), do: nil
  defp effective_service_time(time, nil), do: time
  defp effective_service_time(time, {_low, high}), do: DateTime.add(time, -high, :minute)

  @spec last_trip_departed?(destination_key(), DateTime.t()) :: boolean()
  defp last_trip_departed?({stop_id, _line_id, headsign} = destination_key, now) do
    departure_times = @last_trip.last_trip_departure_times(destination_key)

    case {red_trunk_to_alewife?(stop_id, headsign), departure_times} do
      {true, [_last_departure_time_one, _last_departure_time_two] = departure_times} ->
        Enum.max(departure_times, DateTime)

      {false, [last_departure_time]} ->
        last_departure_time

      _ ->
        nil
    end
    |> after_last_trip_with_buffer?(now)
  end

  @spec group_by_destination([item]) :: %{destination_key() => [item]}
        when item: Departure.t() | Schedule.t()
  defp group_by_destination(items) do
    Enum.group_by(items, fn
      %Departure{} = d -> d |> departure_destination() |> to_destination_key()
      %Schedule{} = s -> s |> schedule_destination() |> to_destination_key()
    end)
  end

  @spec departure_destination(Departure.t()) :: destination()
  defp departure_destination(%Departure{} = departure) do
    {Departure.stop(departure), Departure.route(departure).line,
     Departure.representative_headsign(departure)}
  end

  defp schedule_destination(%Schedule{route: %Route{line: line}, trip: trip, stop: stop}) do
    {stop, line, Trip.representative_headsign(trip)}
  end

  @spec to_destination_key(destination()) :: destination_key()
  defp to_destination_key({%Stop{id: stop_id}, %Line{id: line_id}, headsign}),
    do: {stop_id, line_id, headsign}

  defp create_routes_for_section(
         departures,
         schedules,
         typical_patterns,
         %Query.Params{route_ids: route_id_params, route_type: route_type} = _params
       ) do
    routes_for_section =
      (departures ++ schedules ++ typical_patterns)
      |> Enum.map(fn
        %Departure{} = departure -> Departure.route(departure)
        %RoutePattern{route: route} -> route
        %Schedule{route: route} -> route
      end)
      |> Enum.uniq()
      |> filter_for_route_id_params(route_id_params)
      |> filter_for_route_type_param(route_type)

    enabled_routes_for_section =
      reject_disabled_modes(routes_for_section, @config_cache.disabled_modes())

    {enabled_routes_for_section, routes_for_section}
  end

  @spec filter_for_route_id_params([Route.t()], [String.t()]) :: [Route.t()]
  defp filter_for_route_id_params(all_routes, []), do: all_routes

  defp filter_for_route_id_params(all_routes, route_id_params),
    do: Enum.filter(all_routes, fn route -> route.id in route_id_params end)

  @spec filter_for_route_type_param([Route.t()], RouteType.t()) :: [Route.t()]
  defp filter_for_route_type_param(all_routes, nil), do: all_routes

  defp filter_for_route_type_param(all_routes, route_type),
    do: Enum.filter(all_routes, fn route -> route.type == route_type end)

  defp reject_disabled_modes(all_routes, []), do: all_routes

  defp reject_disabled_modes(all_routes, disabled_modes),
    do: Enum.reject(all_routes, fn route -> route.type in disabled_modes end)

  @spec fetch_relevant_alerts([Stop.id()], DateTime.t()) :: {:ok, [Alert.t()]} | :error
  defp fetch_relevant_alerts(stop_ids, now) do
    with {:ok, alerts} <- @alert.fetch(activities: [:board], stop_ids: stop_ids) do
      {:ok, Enum.filter(alerts, &(Alert.active?(&1, now) and relevant_alert_effect?(&1)))}
    end
  end

  @spec relevant_alert_effect?(Alert.t()) :: boolean()
  defp relevant_alert_effect?(%Alert{effect: effect}) when effect in @relevant_alert_effects,
    do: true

  defp relevant_alert_effect?(_), do: false

  @spec informed_destinations([destination()], [Alert.t()], [RoutePattern.t()]) ::
          MapSet.t(destination())
  defp informed_destinations(destinations, alerts, typical_patterns) do
    # Filters destinations to return only those that are affected by at least one alert.
    # Stops checking as soon as an alert is found that affects the destination.
    destinations
    |> Enum.filter(fn {stop, _line, _headsign} = destination ->
      case pattern_for_destination(destination, typical_patterns) do
        nil ->
          nil

        pattern ->
          Enum.any?(alerts, fn alert ->
            Enum.any?(alert.informed_entities, fn ie ->
              ie_affects_destination?(ie, pattern, stop)
            end)
          end)
      end
    end)
    |> MapSet.new()
  end

  @spec pattern_for_destination(destination(), [RoutePattern.t()]) :: RoutePattern.t() | nil
  defp pattern_for_destination({stop, line, headsign}, typical_patterns) do
    Enum.find(typical_patterns, fn %RoutePattern{
                                     headsign: pattern_headsign,
                                     route: %Route{line: pattern_line},
                                     stops: pattern_stops
                                   } ->
      line == pattern_line and headsign == pattern_headsign and
        Enum.any?(pattern_stops, fn pattern_stop -> stop.id == pattern_stop.id end)
    end)
  end

  @spec ie_affects_destination?(InformedEntity.t(), RoutePattern.t(), Stop.t()) :: boolean()
  # Alert effects the entire route
  defp ie_affects_destination?(
         %InformedEntity{route: route_id, direction_id: nil, stop: nil},
         %RoutePattern{route: %Route{id: route_id}},
         _home_stop
       ),
       do: true

  # Alert effects the entire route in the direction of the destination
  defp ie_affects_destination?(
         %InformedEntity{route: route_id, direction_id: direction_id, stop: nil},
         %RoutePattern{route: %Route{id: route_id}, direction_id: direction_id},
         _home_stop
       ),
       do: true

  # Alert effects the entire route in both directions
  defp ie_affects_destination?(
         %InformedEntity{route_type: informed_route_type, stop: nil},
         %RoutePattern{route: %Route{type: route_type}},
         _home_stop
       ),
       do: RouteType.to_id(route_type) == informed_route_type

  # Alert does not affect the route or a specific stop
  defp ie_affects_destination?(%InformedEntity{stop: nil}, _pattern, _home_stop),
    do: false

  # Alert effects the child stop
  defp ie_affects_destination?(%InformedEntity{stop: %Stop{id: id}}, _pattern, %Stop{id: id}),
    do: true

  defp ie_affects_destination?(_, _, _), do: false

  defp red_trunk_to_alewife?(stop_id, "Alewife") when stop_id in @red_trunk, do: true

  defp red_trunk_to_alewife?(_stop_id, _headsign), do: false

  defp after_last_trip_with_buffer?(nil, _now), do: false

  defp after_last_trip_with_buffer?(last_trip_departure_time, now) do
    departure_time_with_buffer =
      DateTime.add(
        last_trip_departure_time,
        @last_trip_buffer_seconds,
        :second
      )

    DateTime.after?(now, departure_time_with_buffer)
  end
end
