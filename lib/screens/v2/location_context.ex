defmodule Screens.LocationContext do
  @moduledoc false

  require Logger

  alias Screens.RoutePatterns.RoutePattern
  alias Screens.Routes.Route
  alias Screens.RouteType
  alias Screens.Stops.Stop
  alias Screens.Util

  alias ScreensConfig.V2.{BusEink, BusShelter, Dup, Elevator, GlEink, PreFare}

  @enforce_keys [:home_stop]
  defstruct home_stop: "",
            home_stop_name: "",
            tagged_stop_sequences: %{},
            upstream_stops: MapSet.new(),
            downstream_stops: MapSet.new(),
            routes: [],
            alert_route_types: []

  @type t :: %__MODULE__{
          home_stop: Stop.id(),
          home_stop_name: String.t(),
          # Stop sequences through this stop, keyed under their associated routes
          tagged_stop_sequences: %{Route.id() => list(list(Stop.id()))},
          upstream_stops: MapSet.t(Stop.id()),
          downstream_stops: MapSet.t(Stop.id()),
          # Routes serving this stop
          routes: list(%{route_id: Route.id(), active?: boolean()}),
          # Route types we care about for the alerts of this screen type / place
          alert_route_types: list(RouteType.t())
        }

  @type screen_type :: BusEink | BusShelter | Dup | GlEink | PreFare

  @doc """
  Fetches all the location context for a screen given its app type, stop id, and time
  """
  @callback fetch(screen_type(), Stop.id(), DateTime.t()) :: {:ok, t()} | :error
  def fetch(app, stop_id, now) do
    Screens.Telemetry.span(
      ~w[screens location_context fetch]a,
      %{app: app, stop_id: stop_id},
      fn ->
        with alert_route_types <- route_type_filter(app, stop_id),
             {:ok, routes_at_stop} <-
               Route.serving_stop_with_active(stop_id, now, alert_route_types),
             {:ok, tagged_stop_sequences} <-
               fetch_tagged_stop_sequences_by_app(app, stop_id, routes_at_stop) do
          stop_name = Stop.fetch_stop_name(stop_id)
          stop_sequences = RoutePattern.untag_stop_sequences(tagged_stop_sequences)

          {
            :ok,
            %__MODULE__{
              home_stop: stop_id,
              home_stop_name: stop_name,
              tagged_stop_sequences: tagged_stop_sequences,
              upstream_stops: upstream_stop_id_set(stop_id, stop_sequences),
              downstream_stops: downstream_stop_id_set(stop_id, stop_sequences),
              routes: routes_at_stop,
              alert_route_types: alert_route_types
            }
          }
        else
          :error ->
            Logger.error(
              "[location_context fetch error] Failed to get location context for an alert: stop_id=#{stop_id}"
            )

            :error
        end
      end
    )
  end

  # Returns the route types we care about for the alerts of this screen type / place
  @spec route_type_filter(screen_type(), String.t()) :: list(RouteType.t())
  def route_type_filter(app, _) when app in [BusEink, BusShelter], do: [:bus]
  def route_type_filter(GlEink, _), do: [:light_rail]
  # Ashmont should not show Mattapan alerts for PreFare or Dup
  def route_type_filter(app, "place-asmnl") when app in [PreFare, Dup], do: [:subway]
  def route_type_filter(PreFare, _), do: [:light_rail, :subway]
  # WTC is a special bus-only case
  def route_type_filter(Dup, "place-wtcst"), do: [:bus]
  def route_type_filter(Dup, _), do: [:light_rail, :subway]
  def get_route_type_filter(Elevator, _), do: [:subway]

  @spec upstream_stop_id_set(String.t(), list(list(Stop.id()))) :: MapSet.t(Stop.id())
  def upstream_stop_id_set(stop_id, stop_sequences) do
    stop_sequences
    |> Enum.flat_map(fn stop_sequence -> Util.slice_before(stop_sequence, stop_id) end)
    |> MapSet.new()
  end

  @spec downstream_stop_id_set(String.t(), list(list(Stop.id()))) :: MapSet.t(Stop.id())
  def downstream_stop_id_set(stop_id, stop_sequences) do
    stop_sequences
    |> Enum.flat_map(fn stop_sequence -> Util.slice_after(stop_sequence, stop_id) end)
    |> MapSet.new()
  end

  @doc """
  Returns IDs of routes that serve this location.
  """
  @spec route_ids(t()) :: list(Route.id())
  def route_ids(%__MODULE__{} = t) do
    Route.route_ids(t.routes)
  end

  @doc """
  Returns the stop sequences of routes that serve this location.
  Sequences follow the order of direction_id=0 for their respective routes.
  Generally, this means they go from north/east -> south/west.
  """
  @spec stop_sequences(t()) :: list(list(Stop.id()))
  def stop_sequences(%__MODULE__{} = t) do
    RoutePattern.untag_stop_sequences(t.tagged_stop_sequences)
  end

  defp fetch_tagged_stop_sequences_by_app(app, stop_id, _routes_at_stop)
       when app in [BusEink, BusShelter, GlEink] do
    RoutePattern.fetch_tagged_stop_sequences_through_stop(stop_id)
  end

  defp fetch_tagged_stop_sequences_by_app(Dup, stop_id, routes_at_stop) do
    route_ids = Route.route_ids(routes_at_stop)
    RoutePattern.fetch_tagged_parent_station_sequences_through_stop(stop_id, route_ids)
  end

  defp fetch_tagged_stop_sequences_by_app(app, stop_id, routes_at_stop)
       when app in [Elevator, PreFare] do
    route_ids = Route.route_ids(routes_at_stop)

    # We limit results to canonical route patterns only--no stop sequences for nonstandard patterns.
    RoutePattern.fetch_tagged_parent_station_sequences_through_stop(stop_id, route_ids, true)
  end
end
