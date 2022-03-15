defmodule Screens.RoutePatterns.RoutePattern do
  @moduledoc false

  alias Screens.RoutePatterns
  alias Screens.Routes.Route
  alias Screens.Stops.Stop
  alias Screens.Trips.Trip
  alias Screens.V3Api

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
          route_id: Route.id(),
          representative_trip_id: Trip.id()
        }

  def stops_by_route_and_direction(route_id, direction_id) do
    case V3Api.get_json("route_patterns", %{
           "filter[route]" => route_id,
           "filter[direction_id]" => direction_id,
           "sort" => "typicality",
           "include" => "representative_trip.stops"
         }) do
      {:ok, result} -> {:ok, RoutePatterns.Parser.parse_result(result, route_id)}
      _ -> :error
    end
  end

  @spec fetch_stop_sequences_through_stop(Stop.id()) :: {:ok, list(list(Stop.id()))} | :error
  def fetch_stop_sequences_through_stop(
        stop_id,
        type_filters \\ [],
        get_json_fn \\ &V3Api.get_json/2
      ) do
    params = %{
      "include" => "representative_trip.stops,route",
      "filter[stop]" => stop_id
    }

    params =
      if length(type_filters) > 0 do
        Map.merge(params, %{"filter[route]" => Enum.join(type_filters, ",")})
      else
        params
      end

    case get_json_fn.("route_patterns", params) do
      {:ok, result} ->
        stop_sequences =
          get_in(result, [
            "included",
            Access.filter(&(&1["type"] == "trip")),
            "relationships",
            "stops",
            "data",
            Access.all(),
            "id"
          ])

        {:ok, stop_sequences}

      _ ->
        :error
    end
  end
end
