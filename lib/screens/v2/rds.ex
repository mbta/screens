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
  alias Screens.RoutePatterns.RoutePattern
  alias Screens.Routes.Route
  alias Screens.RouteType
  alias Screens.Schedules.Schedule
  alias Screens.Stops.Stop
  alias Screens.Util

  alias Screens.V2.Departure

  alias ScreensConfig.Departures
  alias ScreensConfig.Departures.{Query, Section}

  alias __MODULE__.Countdowns
  alias __MODULE__.FirstTrip
  alias __MODULE__.NoService
  alias __MODULE__.ServiceEnded

  @type t ::
          %__MODULE__{
            stop: Stop.t(),
            line: Line.t(),
            headsign: String.t(),
            state: NoService.t() | Countdowns.t() | FirstTrip.t()
          }
  @enforce_keys ~w[stop line headsign state]a
  defstruct @enforce_keys

  @type section_t :: {:ok, [t()]} | :error
  @type destination :: {Stop.t(), Line.t(), String.t()}
  @type destination_key :: {Stop.id(), Line.id(), String.t()}
  @type rds_state :: NoService.t() | Countdowns.t() | FirstTrip.t() | ServiceEnded.t()
  @type service_state ::
          :before_scheduled_start
          | :after_scheduled_end
          | :active_period
          | :service_impacted
          | :no_service

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
    @type t :: %__MODULE__{routes: [Route.t()]}
    defstruct ~w[routes]a
  end

  defmodule Countdowns do
    @moduledoc """
    State when there is upcoming service to a destination
    and/or alerts which affect service to the destination.
    """
    @type t :: %__MODULE__{departures: [Departure.t()]}
    defstruct ~w[departures]a
  end

  defmodule FirstTrip do
    @moduledoc """
    State when we are in a new service day and are
    showing the first scheduled trip of the day for a
    given destination.
    """
    @type t :: %__MODULE__{first_scheduled_departure: Departure.t()}
    defstruct ~w[first_scheduled_departure]a
  end

  defmodule ServiceEnded do
    @moduledoc """
    State for after the end of the last scheduled departure
    or if we observe a departure that is the Last Trip of the Day
    """
    @type t :: %__MODULE__{last_scheduled_departure: Departure.t()}
    defstruct ~w[last_scheduled_departure]a
  end

  defmodule Headways do
    @moduledoc """
    State for if we're in an active period, but we have no predictions
    and there are no alerts associated with the destination.

    Shows an every “X-Y” minutes message. 
    """
    @type t :: %__MODULE__{
            departure: Departure.t(),
            route_id: Route.id(),
            direction_name: String.t(),
            range: Headway.range()
          }
    defstruct ~w[departure route_id direction_name range]a
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
    do: Enum.map(sections, &from_section(&1, now))

  @spec from_section(Section.t(), DateTime.t()) :: section_t()
  defp from_section(
         %Section{query: %Query{params: %Query.Params{stop_ids: stop_ids} = params}},
         now
       )
       when stop_ids != [] do
    with {:ok, typical_patterns} <-
           params
           |> Map.from_struct()
           |> Map.put(:typicality, 1)
           |> @route_pattern.fetch(),
         {:ok, child_stops} <-
           fetch_child_stops(stop_ids),
         {:ok, scheduled} <-
           @schedule.fetch(%{stop_ids: stop_ids}, Util.service_date(now)),
         {:ok, alerts} <-
           fetch_relevant_alerts(stop_ids),
         {:ok, departures} <-
           params
           |> Map.from_struct()
           |> @departure.fetch(now: now) do
      scheduled_departures =
        Enum.map(scheduled, fn schedule -> %Departure{prediction: nil, schedule: schedule} end)

      case create_routes_for_section(
             departures,
             scheduled_departures,
             typical_patterns,
             params
           ) do
        {[_ | _] = enabled_routes_for_section, _} ->
          create_section_rds(
            departures,
            scheduled_departures,
            typical_patterns,
            child_stops,
            enabled_routes_for_section,
            alerts,
            now
          )

        {[], [_ | _] = _routes_for_section} ->
          {:ok, []}

        _ ->
          :error
      end
    end
  end

  @spec fetch_child_stops([Stop.id()]) :: {:ok, [Stop.id()]} | :error
  defp fetch_child_stops(stop_ids) do
    with {:ok, stops} <- @stop.fetch(%{ids: stop_ids}, _include_related? = true) do
      stops_by_id = Map.new(stops, fn %Stop{id: id} = stop -> {id, stop} end)

      child_stop_ids =
        stop_ids
        |> Enum.map(&stops_by_id[&1])
        |> Enum.flat_map(fn
          %Stop{location_type: 0} = stop -> [stop]
          %Stop{child_stops: stops} when is_list(stops) -> stops
          # stop ID in screen configuration does not exist; drop it
          nil -> []
        end)

      {:ok, child_stop_ids}
    end
  end

  defp create_section_rds(
         departures,
         scheduled_departures,
         typical_patterns,
         child_stops,
         routes_for_section,
         alerts,
         now
       ) do
    departures_by_destination = group_by_destination(departures)
    scheduled_departures_by_destination = group_by_destination(scheduled_departures)

    destinations =
      (tuples_from_departures(departures, now) ++
         tuples_from_patterns(typical_patterns, child_stops))
      |> Enum.uniq_by(fn {stop, line, headsign} -> {stop.id, line.id, headsign} end)

    # Destinations that are affected by current alerts at the present stop ID
    impacted_destinations = informed_destinations(destinations, alerts, typical_patterns)

    section_rds =
      destinations
      |> Enum.map(fn destination ->
        create_destination_rds(
          destination,
          departures_by_destination,
          scheduled_departures_by_destination,
          routes_for_section,
          impacted_destinations,
          now
        )
      end)

    {:ok, section_rds}
  end

  defp create_destination_rds(
         {%Stop{id: stop_id} = stop, %Line{id: line_id} = line, headsign} = destination,
         departures_by_destination,
         scheduled_departures_by_destination,
         routes_for_section,
         impacted_destinations,
         now
       ) do
    headway_for_stop = @headways.get(stop_id, now)
    destination_key = {stop_id, line_id, headsign}

    departures =
      Map.get(departures_by_destination, destination_key, [])
      |> Enum.filter(fn
        %{prediction: nil} -> headway_for_stop == nil
        _ -> true
      end)

    scheduled_departures =
      scheduled_departures_by_destination |> Map.get(destination_key, [])

    impacted_by_alert = destination in impacted_destinations

    %__MODULE__{
      stop: stop,
      line: line,
      headsign: headsign,
      state:
        state(
          departures,
          scheduled_departures,
          destination_key,
          routes_for_section,
          headway_for_stop,
          impacted_by_alert,
          now
        )
    }
  end

  @spec tuples_from_departures([Departure.t()], DateTime.t()) :: [destination()]
  defp tuples_from_departures(departures, now) do
    departures
    |> Enum.filter(&(DateTime.diff(Departure.time(&1), now, :minute) <= @max_departure_minutes))
    |> Enum.map(&destination_from_departure(&1))
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

  @spec state(
          [Departure.t()],
          [Departure.t()],
          destination_key(),
          [Route.t()],
          Headway.range() | nil,
          boolean(),
          DateTime.t()
        ) :: rds_state()
  defp state(
         [] = _departures_for_headsign,
         [] = _scheduled_departures_for_headsign,
         _destination_key,
         routes_for_section,
         _headway_for_stop,
         false = _impacted_by_alert,
         _now
       ) do
    %NoService{routes: routes_for_section}
  end

  defp state(
         [] = departures_for_headsign,
         [_ | _] = scheduled_departures_for_headsign,
         destination_key,
         routes_for_section,
         headway_for_stop,
         impacted_by_alert,
         now
       ) do
    {first_scheduled_departure, last_scheduled_departure} =
      scheduled_departures_for_headsign
      |> Enum.sort_by(&Departure.time(&1), DateTime)
      |> then(&{List.first(&1), List.last(&1)})

    case classify_service_state(
           first_scheduled_departure,
           last_scheduled_departure,
           headway_for_stop,
           impacted_by_alert,
           after_last_trip?(destination_key, now),
           now
         ) do
      :before_scheduled_start ->
        %FirstTrip{first_scheduled_departure: first_scheduled_departure}

      :after_scheduled_end ->
        %ServiceEnded{last_scheduled_departure: last_scheduled_departure}

      :service_impacted ->
        %Countdowns{departures: departures_for_headsign}

      :no_service ->
        %NoService{routes: routes_for_section}

      :active_period ->
        route = Departure.route(first_scheduled_departure)
        direction_id = Departure.direction_id(first_scheduled_departure)

        %Headways{
          departure: first_scheduled_departure,
          route_id: route.id,
          direction_name:
            route
            |> Route.normalized_direction_names()
            |> Enum.at(direction_id, nil),
          range: headway_for_stop
        }
    end
  end

  defp state(
         departures_for_headsign,
         _scheduled_departures_by_headsign,
         _destination_key,
         _routes_for_section,
         _headway_for_stop,
         _impacted_by_alert,
         _now
       ) do
    %Countdowns{departures: departures_for_headsign}
  end

  @spec after_last_trip?(destination_key(), DateTime.t()) :: boolean()
  # Red Trunk stops need two last trip departures in order to classify as Service Ended
  defp after_last_trip?({stop_id, _line_id, "Alewife"} = destination_key, now)
       when stop_id in @red_trunk do
    case @last_trip.last_trip_departure_times(destination_key) do
      [_departure_time_one, _departure_time_two] = departure_times ->
        departure_times
        |> Enum.max()
        |> after_last_trip_with_buffer?(now)

      _ ->
        false
    end
  end

  defp after_last_trip?(destination_key, now) do
    case @last_trip.last_trip_departure_times(destination_key) do
      [departure_time] ->
        after_last_trip_with_buffer?(departure_time, now)

      _ ->
        false
    end
  end

  @spec group_by_destination([Departure.t()]) :: %{destination_key() => [Departure.t()]}
  defp group_by_destination(departures) do
    Enum.group_by(departures, fn departure ->
      departure
      |> destination_from_departure()
      |> then(fn {%Stop{id: stop_id}, %Line{id: line_id}, headsign} ->
        {stop_id, line_id, headsign}
      end)
    end)
  end

  @spec destination_from_departure(Departure.t()) :: destination()
  defp destination_from_departure(departure) do
    {Departure.stop(departure), Departure.route(departure).line,
     Departure.representative_headsign(departure)}
  end

  defp create_routes_for_section(
         departures,
         scheduled_departures,
         typical_patterns,
         %Query.Params{route_ids: route_id_params, route_type: route_type} = _params
       ) do
    routes_for_section =
      (departures ++ scheduled_departures ++ typical_patterns)
      |> Enum.map(fn
        %Departure{} = departure -> Departure.route(departure)
        %RoutePattern{route: route} -> route
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

  @spec classify_service_state(
          Departure.t(),
          Departure.t(),
          Headway.range() | nil,
          boolean(),
          boolean(),
          DateTime.t()
        ) :: service_state()
  defp classify_service_state(
         _first_departure,
         _last_departure,
         _headway_for_stop,
         true,
         _after_last_trip,
         _now
       ),
       do: :service_impacted

  defp classify_service_state(
         _first_departure,
         _last_departure,
         _headway_for_stop,
         _in_alert,
         true,
         _now
       ),
       do: :after_scheduled_end

  defp classify_service_state(
         first_departure,
         last_departure,
         _headway_for_stop,
         _in_alert,
         _after_last_trip,
         _now
       )
       when first_departure == nil and last_departure == nil,
       do: :no_service

  defp classify_service_state(
         first_departure,
         last_departure,
         headway_for_stop,
         _in_alert,
         _after_last_trip,
         now
       ) do
    first_departure_time =
      case headway_for_stop do
        nil ->
          Departure.time(first_departure)

        {_low, high} ->
          first_departure |> Departure.time() |> DateTime.add(-high, :minute)
      end

    last_departure_time = Departure.time(last_departure)

    cond do
      DateTime.compare(now, first_departure_time) == :lt and
          Util.service_date(now) == Util.service_date(Departure.time(first_departure)) ->
        :before_scheduled_start

      DateTime.compare(now, last_departure_time) == :gt and
          Util.service_date(now) == Util.service_date(Departure.time(last_departure)) ->
        :after_scheduled_end

      true ->
        :active_period
    end
  end

  @spec fetch_relevant_alerts([Stop.id()]) :: {:ok, [Alert.t()]} | :error
  defp fetch_relevant_alerts(stop_ids) do
    with {:ok, alerts} <-
           @alert.fetch(activities: [:board], stop_id: stop_ids, include_all?: true) do
      {:ok, Enum.filter(alerts, &(Alert.happening_now?(&1) and relevant_alert_effect?(&1)))}
    end
  end

  @spec relevant_alert_effect?(Alert.t()) :: boolean()
  defp relevant_alert_effect?(%Alert{effect: effect}) when effect in @relevant_alert_effects,
    do: true

  defp relevant_alert_effect?(_), do: false

  @spec informed_destinations([destination()], [Alert.t()], [RoutePattern.t()]) :: [destination()]
  defp informed_destinations(destinations, alerts, typical_patterns) do
    # Filters destinations to return only those that are affected by at least one alert.
    # Stops checking as soon as an alert is found that affects the destination.
    Enum.filter(destinations, fn {stop, _line, _headsign} = destination ->
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
