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

  alias Screens.Headways
  alias Screens.Lines.Line
  alias Screens.RoutePatterns.RoutePattern
  alias Screens.Routes.Route
  alias Screens.Stops.Stop
  alias Screens.V2.Departure

  alias ScreensConfig.Departures
  alias ScreensConfig.Departures.{Query, Section}

  alias __MODULE__.Countdowns
  alias __MODULE__.NoDepartures

  @type t ::
          %__MODULE__{
            stop: Stop.t(),
            line: Line.t(),
            headsign: String.t(),
            state: NoDepartures.t() | Countdowns.t()
          }
  @enforce_keys ~w[stop line headsign state]a
  defstruct @enforce_keys

  @type section_t :: {:ok, [t()]} | :error

  defmodule NoDepartures do
    @moduledoc """
    The fallback state, presented as a headway or "no departures" message. A destination is in
    this state when A) displaying departures has been manually disabled for the relevant transit
    mode, or B) there simply aren't any upcoming departures we want to display, and as far as we
    can tell this is "normal"/expected.
    """
    @type t :: %__MODULE__{headways: Headways.range() | nil}
    defstruct ~w[headways]a
  end

  defmodule Countdowns do
    @moduledoc """
    State when there is upcoming service to a destination 
    and/or alerts which affect service to the destination.
    """
    @type t :: %__MODULE__{departures: [Departure.t()]}
    defstruct ~w[departures]a
  end

  @departure injected(Departure)
  @headways injected(Headways)
  @route_pattern injected(RoutePattern)
  @stop injected(Stop)

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
         {:ok, departures} <-
           params
           |> Map.from_struct()
           |> @departure.fetch(now: now) do
      departures_by_destination =
        departures
        |> Enum.group_by(fn departure ->
          departure
          |> destination_from_departure()
          |> then(fn {%Stop{id: stop_id}, %Line{id: line_id}, headsign} ->
            {stop_id, line_id, headsign}
          end)
        end)

      section_rds =
        (tuples_from_departures(departures, now) ++
           tuples_from_patterns(typical_patterns, child_stops))
        |> Enum.uniq()
        |> Enum.map(fn {%Stop{id: stop_id} = stop, line, headsign} ->
          headway_for_stop = @headways.get(stop_id, now)

          departures_for_headsign =
            Map.get(departures_by_destination, {stop.id, line.id, headsign}, [])
            |> Enum.filter(fn
              %{prediction: nil} -> headway_for_stop == nil
              _ -> true
            end)

          %__MODULE__{
            stop: stop,
            line: line,
            headsign: headsign,
            state: state(departures_for_headsign, stop_id, now)
          }
        end)

      {:ok, section_rds}
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

  defp tuples_from_departures(departures, now) do
    departures
    |> Enum.filter(&(DateTime.diff(Departure.time(&1), now, :minute) <= @max_departure_minutes))
    |> Enum.map(&destination_from_departure(&1))
  end

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

  defp destination_from_departure(departure) do
    {Departure.stop(departure), Departure.route(departure).line,
     Departure.representative_headsign(departure)}
  end

  defp state([] = _departures_by_headsign, _stop_id, _now) do
    %NoDepartures{}
  end

  defp state(departures_by_headsign, _stop_id, _now) do
    %Countdowns{departures: departures_by_headsign}
  end
end
