# Script to find connecting routes for stops along a given route pattern.
# Used to determine which connections should be shown on vehicle screens.
#
# Edited on 06/23/22 to get stop data from the trips endpoint instead of route_patterns, so that we can use a date filter.
# The date filter is necessary to get service for a particular rating (even when both old/new ratings are in prod)
#
# TODO: Now that the date filter is added, we can get the old and new ratings at the same time and compare them automatically instead of manually.
# TODO: The script is largely correct, but there were a couple oddities... For example: CR-Foxboro was left out as a current transfer option at South Station
# but that trip still seems to be running. Why was it left out?
#
# API_V3_KEY should be set in the environment via command line or just set in the .envrc file
#
# Example usages:
# mix run scripts/connecting_routes.exs --service-date 2022-06-25
# mix run scripts/connecting_routes.exs --service-date 2022-06-25 --route-pattern "Red-3-0"

# To prevent info logs from the application
Logger.configure(level: :warning)

{opts, _, _ } =
  System.argv()
  |> OptionParser.parse(strict: [service_date: :string, route_pattern: :string])
service_date = Keyword.get(opts, :service_date)
single_route_pattern = Keyword.get(opts, :route_pattern)
route_patterns = [
  "Red-3-0",
  "Red-1-0",
  "Orange-3-0",
  "Green-B-812-0",
  "Green-C-832-0",
  "Green-D-855-0",
  "Green-E-886-0",
]

defmodule RouteConnections do
 def calculate(route_pattern_id, service_date) do
 
  api_v3_key = System.get_env("API_V3_KEY")
  headers = [{"x-api-key", api_v3_key}]

  {:ok, %{status_code: 200, body: body}} = HTTPoison.get("https://api-v3.mbta.com/trips?filter[route_pattern]=#{route_pattern_id}&filter[date]=#{service_date}&include=stops.parent_station.connecting_stops,stops.parent_station.child_stops", headers)
  {:ok, parsed} = Jason.decode(body)

  %{"included" => included} = parsed

  included_stops =
    included
    |> Enum.filter(fn %{"type" => type} -> type == "stop" end)
    |> Enum.map(fn %{"id" => id} = stop -> {id, stop} end)
    |> Enum.into(%{})

  route_pattern_station_ids =
    included
    |> Enum.filter(fn %{"relationships" => relationships} -> Map.has_key?(relationships, "connecting_stops") end)
    |> Enum.map(fn %{"id" => id} -> id end)

  # This bit makes sense for us: we need all the routes for all stops at this station
  # including child stops and nearby stops (called connecting stops)
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
  |> Enum.sort()

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
    url = "https://api-v3.mbta.com/routes?filter[listed_route]=true"
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
  end
end

if single_route_pattern == nil do
  route_patterns
  |> Enum.each(fn route ->
    IO.puts("Calculating connections for: #{route}")
    routes_by_station = RouteConnections.calculate(route, service_date)
    IO.puts(routes_by_station, width: 240)

    # To avoid getting rate limited
    :timer.sleep(1000)
  end)
else
  IO.puts("Calculating connections for: #{single_route_pattern}")
  routes_by_station = RouteConnections.calculate(single_route_pattern, service_date)
  IO.puts(routes_by_station, width: 240)
end


