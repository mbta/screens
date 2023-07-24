defmodule Screens.LocationContext do
  @moduledoc false

  alias Screens.Routes.Route
  alias Screens.RouteType
  alias Screens.Stops.Stop

  @enforce_keys [:home_stop]
  defstruct home_stop: "",
            home_stop_name: "",
            stop_sequences: [],
            upstream_stops: MapSet.new(),
            downstream_stops: MapSet.new(),
            routes: [],
            alert_route_types: []

  @type t :: %__MODULE__{
          home_stop: Stop.id(),
          home_stop_name: String.t(),
          stop_sequences: list(list(Stop.id())),
          upstream_stops: MapSet.t(Stop.id()),
          downstream_stops: MapSet.t(Stop.id()),
          routes: list(%{route_id: Route.id(), active?: boolean()}),
          alert_route_types: list(RouteType.t())
        }
end
