# Script to find connecting routes for stops along a given route pattern.
# Used to determine which connections should be shown on vehicle screens.
#
# Example usage: API_V3_KEY=<your_key_here> mix run scripts/connecting_routes.exs --route-pattern Orange-3-0

{opts, _, _ } =
  System.argv()
  |> OptionParser.parse(strict: [route_pattern: :string])

route_pattern_id = Keyword.get(opts, :route_pattern)
api_v3_key = System.get_env("API_V3_KEY")

url = "https://api-v3.mbta.com/route_patterns/#{route_pattern_id}?include=representative_trip.stops.parent_station.connecting_stops,representative_trip.stops.parent_station.child_stops"
headers = [{"x-api-key", api_v3_key}]
{:ok, %{status_code: 200, body: body}} = HTTPoison.get(url, headers)
{:ok, parsed} = Jason.decode(body)

%{"data" => data, "included" => included} = parsed

included_stops =
  included
  |> Enum.filter(fn %{"type" => type} -> type == "stop" end)
  |> Enum.map(fn %{"id" => id} = stop -> {id, stop} end)
  |> Enum.into(%{})

representative_trip_id = Kernel.get_in(data, ["relationships", "representative_trip", "data", "id"])
representative_trip = Enum.find(included, fn %{"id" => id, "type" => type} -> id == representative_trip_id && type == "trip" end)
route_pattern_stop_data = Kernel.get_in(representative_trip, ["relationships", "stops", "data"])
route_pattern_stop_ids = Enum.map(route_pattern_stop_data, fn %{"id" => id} -> id end)
route_pattern_station_ids = Enum.map(route_pattern_stop_ids, fn stop_id ->
  Kernel.get_in(included_stops, [stop_id, "relationships", "parent_station", "data", "id"])
end)

transfer_stops_by_station = Enum.map(route_pattern_station_ids, fn station_id ->
  station = Map.get(included_stops, station_id)

  connecting_stop_ids =
    station
    |> Kernel.get_in(["relationships", "connecting_stops", "data"])
    |> Enum.map(fn %{"id" => id} -> id end)

  child_stop_ids =
    station
    |> Kernel.get_in(["relationships", "child_stops", "data"])
    |> Enum.map(fn %{"id" => id} -> id end)

  connecting_stops =
    connecting_stop_ids
    |> Enum.map(&Map.get(included_stops, &1))
    |> Enum.filter(fn stop -> Kernel.get_in(stop, ["attributes", "location_type"]) == 0 end)

  child_stops =
    child_stop_ids
    |> Enum.map(&Map.get(included_stops, &1))
    |> Enum.filter(fn stop -> Kernel.get_in(stop, ["attributes", "location_type"]) == 0 end)

  stops = connecting_stops ++ child_stops
  {station_id, Enum.map(stops, fn %{"id" => id} -> id end)}
end)

transfer_stop_list = Enum.flat_map(transfer_stops_by_station, fn {_station_id, stops} -> stops end)

get_typical_routes = fn (stop) ->
  url = "https://api-v3.mbta.com/route_patterns?filter[stop]=#{URI.encode(stop)}"
  headers = [{"x-api-key", api_v3_key}]
  {:ok, %{status_code: 200, body: body}} = HTTPoison.get(url, headers)
  {:ok, %{"data" => route_patterns_data}} = Jason.decode(body)

  routes =
    route_patterns_data
    |> Enum.filter(fn route_pattern -> Kernel.get_in(route_pattern, ["attributes", "typicality"]) < 3 end)
    |> Enum.map(fn route_pattern -> Kernel.get_in(route_pattern, ["relationships", "route", "data", "id"]) end)
    |> Enum.uniq()

  {stop, routes}
end

fetch_all_routes = fn ->
  url = "https://api-v3.mbta.com/routes"
  headers = [{"x-api-key", api_v3_key}]
  {:ok, %{status_code: 200, body: body}} = HTTPoison.get(url, headers)
  {:ok, %{"data" => routes_data}} = Jason.decode(body)

  routes_data
  |> Enum.map(fn %{"id" => id} = route -> {id, route} end)
  |> Enum.into(%{})
end

all_routes_by_id = fetch_all_routes.()

routes_by_stop = transfer_stop_list
  |> Enum.map(&get_typical_routes.(&1))
  |> Enum.into(%{})

routes_by_station =
  transfer_stops_by_station
  |> Enum.map(fn {station_id, stop_ids} ->
    connecting_routes =
      stop_ids
      |> Enum.flat_map(fn stop_id -> Map.get(routes_by_stop, stop_id) end)
      |> Enum.uniq()
      |> Enum.sort_by(fn route_id ->
        Kernel.get_in(all_routes_by_id, [route_id, "attributes", "sort_order"])
      end)

    {String.to_atom(station_id), connecting_routes}
  end)

_ = IO.inspect(routes_by_station, width: 240)
