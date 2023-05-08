defmodule Screens.LocationContext do
  @moduledoc false

  alias Screens.Routes.Route
  alias Screens.RouteType
  alias Screens.Stops.Stop

  defstruct home_stop: "",
            stop_sequences: [],
            upstream_stops: nil,
            downstream_stops: nil,
            routes: [],
            route_ids_at_stop: [],
            alert_route_types: []

  @type t :: %__MODULE__{
          home_stop: Stop.id(),
          stop_sequences: list(list(Stop.id())),
          upstream_stops: MapSet.t(Stop.id()),
          downstream_stops: MapSet.t(Stop.id()),
          routes: list(%{route_id: Route.id(), active?: boolean()}),
          route_ids_at_stop: list(Route.id()),
          alert_route_types: list(RouteType.t())
        }
end
