defmodule Screens.LocationContext do
  @moduledoc false

  alias Screens.Report
  alias Screens.RoutePatterns.RoutePattern
  alias Screens.Routes.Route
  alias Screens.RouteType
  alias Screens.Stops.Stop
  alias Screens.Util

  alias ScreensConfig.Screen.{BusEink, BusShelter, Dup, GlEink, PreFare}

  @enforce_keys [:home_stop]
  defstruct home_stop: "",
            tagged_stop_sequences: %{},
            upstream_stops: MapSet.new(),
            downstream_stops: MapSet.new(),
            routes: [],
            alert_route_types: []

  @type t :: %__MODULE__{
          home_stop: Stop.id() | nil,
          # Stop sequences through the stops, keyed under their associated routes
          tagged_stop_sequences: %{Route.id() => list(list(Stop.id()))},
          upstream_stops: MapSet.t(Stop.id()),
          downstream_stops: MapSet.t(Stop.id()),
          # Routes serving the stops
          routes: list(%{route_id: Route.id(), active?: boolean()}),
          # Route types we care about for the alerts of this screen type / place
          alert_route_types: list(RouteType.t())
        }

  @type screen_type :: BusEink | BusShelter | Dup | GlEink | PreFare

  @doc """
  Fetches all the location context for a screen given its app type, home stop ID, and time.

  Note: Multiple stop IDs are accepted, but this is intended only for edge cases where a screen
  serves a cluster of standalone stops conceptually similar to a parent station but not actually
  modeled as one. In this case, `home_stop` will be `nil`. This is only allowed on screen types
  where we know it will not cause major issues, and has intentionally minimal support on those
  screen types (e.g. "does this alert affect the home stop" conditions will always be false).
  """
  @spec fetch(screen_type(), Stop.id() | [Stop.id()], DateTime.t()) :: {:ok, t()} | :error
  def fetch(app, stop_id, now) when is_binary(stop_id), do: do_fetch(app, [stop_id], now)
  def fetch(app, [_] = stop_ids, now), do: do_fetch(app, stop_ids, now)
  def fetch(BusEink = app, [_ | _] = stop_ids, now), do: do_fetch(app, stop_ids, now)

  defp do_fetch(app, stop_ids, now) do
    Screens.Telemetry.span(
      ~w[screens location_context fetch]a,
      %{app: app, stop_ids: stop_ids},
      fn ->
        with alert_route_types <- route_type_filter(app, stop_ids),
             {:ok, routes_at_stops} <- routes_with_active(stop_ids, alert_route_types, now),
             route_ids_at_stop = Enum.map(routes_at_stops, & &1.route_id),
             {:ok, tagged_stop_sequences} <-
               fetch_tagged_stop_sequences_by_app(app, stop_ids, route_ids_at_stop) do
          stop_sequences = untag_stop_sequences(tagged_stop_sequences)

          {
            :ok,
            %__MODULE__{
              home_stop:
                case stop_ids do
                  [single] -> single
                  _multiple -> nil
                end,
              tagged_stop_sequences: tagged_stop_sequences,
              upstream_stops: upstream_stop_id_set(stop_ids, stop_sequences),
              downstream_stops: downstream_stop_id_set(stop_ids, stop_sequences),
              routes: routes_at_stops,
              alert_route_types: alert_route_types
            }
          }
        else
          :error ->
            Report.error("location_context_fetch_error", stop_ids: stop_ids)
            :error
        end
      end
    )
  end

  # NOTE: only public due to use in tests. Should be treated as private.
  @spec upstream_stop_id_set([Stop.id()], [[Stop.id()]]) :: MapSet.t(Stop.id())
  def upstream_stop_id_set(stop_ids, stop_sequences),
    do: sliced_stop_id_set(stop_ids, stop_sequences, &Util.slice_before/2)

  # NOTE: only public due to use in tests. Should be treated as private.
  @spec downstream_stop_id_set([Stop.id()], [[Stop.id()]]) :: MapSet.t(Stop.id())
  def downstream_stop_id_set(stop_ids, stop_sequences),
    do: sliced_stop_id_set(stop_ids, stop_sequences, &Util.slice_after/2)

  defp sliced_stop_id_set(stop_ids, stop_sequences, slice_fn) do
    stop_ids
    |> Enum.flat_map(fn stop_id ->
      Enum.flat_map(stop_sequences, fn stop_sequence -> slice_fn.(stop_sequence, stop_id) end)
    end)
    |> MapSet.new()
  end

  @doc """
  Returns IDs of routes that serve this location.
  """
  @spec route_ids(t()) :: list(Route.id())
  def route_ids(%__MODULE__{routes: routes}), do: Enum.map(routes, & &1.route_id)

  @doc """
  Returns the stop sequences of routes that serve this location.
  Sequences follow the order of direction_id=0 for their respective routes.
  Generally, this means they go from north/east -> south/west.
  """
  @spec stop_sequences(t()) :: list(list(Stop.id()))
  def stop_sequences(%__MODULE__{} = t), do: untag_stop_sequences(t.tagged_stop_sequences)

  # Returns the route types we care about for the alerts of this screen type / place.
  # NOTE: only public due to use in tests. Should be treated as private.
  @spec route_type_filter(screen_type(), [Stop.id()]) :: list(RouteType.t())
  def route_type_filter(app, _) when app in [BusEink, BusShelter], do: [:bus]
  def route_type_filter(GlEink, _), do: [:light_rail]
  # Ashmont should not show Mattapan alerts for PreFare or Dup
  def route_type_filter(app, ["place-asmnl"]) when app in [PreFare, Dup], do: [:subway]
  def route_type_filter(PreFare, _), do: [:light_rail, :subway]
  # WTC is a special bus-only case
  def route_type_filter(Dup, ["place-wtcst"]), do: [:bus]
  def route_type_filter(Dup, _), do: [:light_rail, :subway]

  defp routes_with_active(stop_ids, route_types, now) do
    params = %{route_types: route_types, stop_ids: stop_ids}

    with {:ok, routes} <- Route.fetch(params),
         {:ok, routes_today} <- params |> Map.put(:date, now) |> Route.fetch() do
      route_ids_today = MapSet.new(routes_today, fn %Route{id: id} -> id end)

      {
        :ok,
        Enum.map(routes, fn %Route{id: id} -> %{route_id: id, active?: id in route_ids_today} end)
      }
    end
  end

  defp fetch_tagged_stop_sequences_by_app(app, stop_ids, _route_ids)
       when app in [BusEink, BusShelter, GlEink] do
    fetch_tagged_stop_sequences_through_stops(stop_ids)
  end

  defp fetch_tagged_stop_sequences_by_app(Dup, stop_ids, route_ids) do
    fetch_tagged_parent_station_sequences_through_stops(stop_ids, route_ids)
  end

  defp fetch_tagged_stop_sequences_by_app(PreFare, stop_ids, route_ids) do
    # We limit results to canonical route patterns only--no stop sequences for nonstandard patterns.
    fetch_tagged_parent_station_sequences_through_stops(stop_ids, route_ids, true)
  end

  # Returns a map from route ID to a list of stop sequences of that route, for all routes serving
  # stop, in all applicable directions.
  @spec fetch_tagged_stop_sequences_through_stops([Stop.id()], [Route.id()]) ::
          {:ok, %{Route.id() => [[Stop.id()]]}} | :error
  defp fetch_tagged_stop_sequences_through_stops(stop_ids, route_ids \\ []) do
    case RoutePattern.fetch(%{stop_ids: stop_ids, route_ids: route_ids}) do
      {:ok, patterns} -> {:ok, get_tagged_stop_sequences(patterns)}
      _ -> :error
    end
  end

  # Returns a map from route ID to a list of stop sequences of that route. Stop sequences are
  # described in terms of parent station IDs, not platform IDs.
  #
  # If no parent station data exists, platform ID is returned instead. Only stop sequences for
  # direction ID 0 are returned. Assumes that all stop sequences in result are platforms.
  @spec fetch_tagged_parent_station_sequences_through_stops([Stop.id()], [Route.id()], boolean()) ::
          {:ok, %{Route.id() => [[Stop.id()]]}} | :error
  defp fetch_tagged_parent_station_sequences_through_stops(
         stop_ids,
         route_ids,
         canonical? \\ false
       ) do
    params = %{stop_ids: stop_ids, route_ids: route_ids}
    params = if(canonical?, do: Map.put(params, :canonical?, true), else: params)

    case RoutePattern.fetch(params) do
      {:ok, []} -> :error
      {:ok, patterns} -> {:ok, get_tagged_parent_station_sequences(patterns)}
      _ -> :error
    end
  end

  # NOTE: only public due to use in tests. Should be treated as private.
  @spec untag_stop_sequences(%{Route.id() => [[Stop.id()]]}) :: [[Stop.id()]]
  def untag_stop_sequences(tagged_stop_sequences),
    do: Enum.flat_map(tagged_stop_sequences, fn {_route_id, sequences} -> sequences end)

  defp get_tagged_stop_sequences(route_patterns) do
    route_patterns
    |> Enum.map(fn %RoutePattern{route: %Route{id: route_id}, stops: stops} ->
      {route_id, Enum.map(stops, fn %Stop{id: id} -> id end)}
    end)
    |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
  end

  defp get_tagged_parent_station_sequences(route_patterns) do
    platform_to_station_map =
      route_patterns
      |> Enum.flat_map(& &1.stops)
      |> Enum.map(fn
        %Stop{id: id, parent_station: nil} -> {id, id}
        %Stop{id: id, parent_station: %Stop{id: parent_id}} -> {id, parent_id}
      end)
      |> Map.new()

    route_patterns
    |> get_tagged_stop_sequences()
    |> Map.new(fn {route_id, stop_sequences} ->
      station_sequences =
        stop_sequences
        |> Enum.map(fn stops -> Enum.map(stops, &Map.fetch!(platform_to_station_map, &1)) end)
        # Dedup the stop sequences (both directions are listed, but we only need 1)
        |> Enum.uniq_by(&MapSet.new/1)

      {route_id, station_sequences}
    end)
  end
end
