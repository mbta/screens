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

  alias Screens.Config.Cache
  alias Screens.Headways
  alias Screens.Lines.Line
  alias Screens.RoutePatterns.RoutePattern
  alias Screens.Routes.Route
  alias Screens.Schedules.Schedule
  alias Screens.Stops.Stop
  alias Screens.Util

  alias Screens.V2.Departure

  alias ScreensConfig.Departures
  alias ScreensConfig.Departures.{Query, Section}

  alias __MODULE__.Countdowns
  alias __MODULE__.FirstTrip
  alias __MODULE__.NoService

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

  @departure injected(Departure)
  @headways injected(Headways)
  @route_pattern injected(RoutePattern)
  @schedule injected(Schedule)
  @stop injected(Stop)
  @config_cache injected(Cache)

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
         %Section{
           query: %Query{
             params: %Query.Params{stop_ids: stop_ids, route_ids: route_id_params} = params
           }
         },
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
             route_id_params
           ) do
        {[_ | _] = enabled_routes_for_section, _} ->
          create_section_rds(
            departures,
            scheduled_departures,
            typical_patterns,
            child_stops,
            enabled_routes_for_section,
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
         now
       ) do
    departures_by_destination = group_by_destination(departures)
    scheduled_departures_by_destination = group_by_destination(scheduled_departures)

    section_rds =
      (tuples_from_departures(departures, now) ++
         tuples_from_patterns(typical_patterns, child_stops))
      |> Enum.uniq()
      |> Enum.map(fn rds ->
        create_destination_rds(
          rds,
          departures_by_destination,
          scheduled_departures_by_destination,
          routes_for_section,
          now
        )
      end)

    {:ok, section_rds}
  end

  defp create_destination_rds(
         {%Stop{id: stop_id} = stop, line, headsign},
         departures_by_destination,
         scheduled_departures_by_destination,
         routes_for_section,
         now
       ) do
    headway_for_stop = @headways.get(stop_id, now)

    departures =
      Map.get(departures_by_destination, {stop.id, line.id, headsign}, [])
      |> Enum.filter(fn
        %{prediction: nil} -> headway_for_stop == nil
        _ -> true
      end)

    scheduled_departures =
      scheduled_departures_by_destination |> Map.get({stop.id, line.id, headsign}, [])

    %__MODULE__{
      stop: stop,
      line: line,
      headsign: headsign,
      state:
        state(
          departures,
          scheduled_departures,
          stop_id,
          routes_for_section,
          headway_for_stop,
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

  defp state(
         [] = _departures_for_headsign,
         [] = _scheduled_departures_for_headsign,
         _stop_id,
         routes_for_section,
         _headway_for_stop,
         _now
       ) do
    %NoService{routes: routes_for_section}
  end

  defp state(
         [] = departures_for_headsign,
         [_ | _] = scheduled_departures_for_headsign,
         _stop_id,
         routes_for_section,
         headway_for_stop,
         now
       ) do
    {first_scheduled_departure, last_scheduled_departure} =
      scheduled_departures_for_headsign
      |> Enum.sort_by(&Departure.time(&1), DateTime)
      |> then(&{List.first(&1), List.last(&1)})

    case time_period_for_state(
           first_scheduled_departure,
           last_scheduled_departure,
           headway_for_stop,
           now
         ) do
      :before_scheduled_start -> %FirstTrip{first_scheduled_departure: first_scheduled_departure}
      # Add Service Ended logic here in future work
      :after_scheduled_end -> %NoService{}
      :active_period -> %Countdowns{departures: departures_for_headsign}
      :no_service -> %NoService{routes: routes_for_section}
    end
  end

  defp state(
         departures_for_headsign,
         _scheduled_departures_by_headsign,
         _stop_id,
         _route_ids_for_section,
         _headway_for_stop,
         _now
       ) do
    %Countdowns{departures: departures_for_headsign}
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
         route_id_params
       ) do
    routes_for_section =
      (departures ++ scheduled_departures ++ typical_patterns)
      |> Enum.map(fn
        %Departure{} = departure -> Departure.route(departure)
        %RoutePattern{route: route} -> route
      end)
      |> Enum.uniq()
      |> filter_for_route_id_params(route_id_params)

    enabled_routes_for_section =
      reject_disabled_modes(routes_for_section, @config_cache.disabled_modes())

    {enabled_routes_for_section, routes_for_section}
  end

  defp filter_for_route_id_params(all_routes, []), do: all_routes

  defp filter_for_route_id_params(all_routes, route_id_params),
    do: Enum.filter(all_routes, fn route -> route.id in route_id_params end)

  defp reject_disabled_modes(all_routes, []), do: all_routes

  defp reject_disabled_modes(all_routes, disabled_modes),
    do: Enum.reject(all_routes, fn route -> route.type in disabled_modes end)

  defp time_period_for_state(first_departure, last_departure, _headway_for_stop, _now)
       when first_departure == nil and last_departure == nil,
       do: :no_service

  defp time_period_for_state(first_departure, last_departure, headway_for_stop, now) do
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
end
