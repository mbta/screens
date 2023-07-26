defmodule Screens.LocationContext do
  @moduledoc false

  alias Screens.Routes.Route
  alias Screens.RouteType
  alias Screens.Stops.Stop

  @enforce_keys [:home_stop]
  defstruct home_stop: "",
            stop_sequences: [],
            upstream_stops: MapSet.new(),
            downstream_stops: MapSet.new(),
            routes: [],
            alert_route_types: []

  @type t :: %__MODULE__{
          home_stop: Stop.id(),
          stop_sequences: list(list(Stop.id())),
          upstream_stops: MapSet.t(Stop.id()),
          downstream_stops: MapSet.t(Stop.id()),
          # Routes serving this stop
          routes: list(%{route_id: Route.id(), active?: boolean()}),
          # Route types we care about for the alerts of this screen type / place
          alert_route_types: list(RouteType.t())
        }
end
