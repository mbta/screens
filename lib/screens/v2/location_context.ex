defmodule Screens.LocationContext do
  @moduledoc false

  alias Screens.RoutePatterns.RoutePattern
  alias Screens.Routes.Route
  alias Screens.RouteType
  alias Screens.Stops.Stop

  @enforce_keys [:home_stop]
  defstruct home_stop: "",
            tagged_stop_sequences: %{},
            upstream_stops: MapSet.new(),
            downstream_stops: MapSet.new(),
            routes: [],
            alert_route_types: []

  @type t :: %__MODULE__{
          home_stop: Stop.id(),
          # Stop sequences through this stop, keyed under their associated routes
          tagged_stop_sequences: %{Route.id() => list(list(Stop.id()))},
          upstream_stops: MapSet.t(Stop.id()),
          downstream_stops: MapSet.t(Stop.id()),
          routes: list(%{route_id: Route.id(), active?: boolean()}),
          alert_route_types: list(RouteType.t())
        }

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
end
