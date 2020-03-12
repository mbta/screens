defmodule Screens.RoutePatterns.RoutePattern do
  @moduledoc false

  defstruct id: nil,
            direction_id: nil,
            typicality: nil,
            route_id: nil,
            representative_trip_id: nil

  @type id :: String.t()

  @type t :: %__MODULE__{
          id: id,
          direction_id: 0 | 1,
          typicality: 1 | 2 | 3 | 4,
          route_id: Screens.Routes.Route.id(),
          representative_trip_id: Screens.Trips.Trip.id()
        }

  def stops_by_route_and_direction(route_id, direction_id) do
    case Screens.V3Api.get_json("route_patterns", %{
           "filter[route]" => route_id,
           "filter[direction_id]" => direction_id,
           "sort" => "typicality",
           "include" => "representative_trip.stops"
         }) do
      {:ok, result} -> Screens.RoutePatterns.Parser.parse_result(result)
    end
  end
end
