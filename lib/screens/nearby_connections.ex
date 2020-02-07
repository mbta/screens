defmodule Screens.NearbyConnections do
  @moduledoc false

  def by_stop_id(stop_id) do
    nearby_connection_stop_ids =
      :screens
      |> Application.get_env(:nearby_connections)
      |> Map.get(stop_id)

    stop_query = Enum.join([stop_id | nearby_connection_stop_ids], ",")

    with {:ok, result} <- Screens.V3Api.get_json("stops", %{"filter[id]" => stop_query}) do
      %{"data" => stops_data} = result

      stops_data
      |> Enum.map(fn stop_data -> parse_stop_data(stop_data) end)
      |> build_nearby_connections(stop_id)
    end
  end

  # need to know:
  # for each nearby stop:
  # - stop name
  # - distance (or walking time)
  # - routes served

  def parse_stop_data(%{
        "attributes" => %{"latitude" => lat, "longitude" => lon, "name" => name},
        "id" => id
      }) do
    %{stop_id: id, stop_name: name, stop_lat: lat, stop_lon: lon}
  end

  def build_nearby_connections(stops_data, stop_id) do
    {stop_data, nearby_stops_data} = split_stops_data(stops_data, stop_id)
    %{stop_lat: stop_lat, stop_lon: stop_lon} = stop_data

    nearby_stops_data
    |> Enum.map(fn stop -> build_nearby_connection(stop, stop_lat, stop_lon) end)
    |> Enum.sort_by(& &1.distance)
  end

  def build_nearby_connection(
        %{stop_lat: nearby_lat, stop_lon: nearby_lon, stop_name: name, stop_id: nearby_id},
        stop_lat,
        stop_lon
      ) do
    distance_miles = distance(stop_lat, stop_lon, nearby_lat, nearby_lon)
    %{name: name, distance: distance_miles, routes: routes_at_stop(nearby_id)}
  end

  def routes_at_stop(stop_id) do
    :screens
    |> Application.get_env(:routes_at_stop)
    |> Map.get(stop_id)
  end

  def split_stops_data(stops_data, stop_id) do
    Enum.reduce(stops_data, {nil, []}, fn %{stop_id: id} = data, {stop_data, nearby_stops_data} ->
      case id do
        ^stop_id ->
          {data, nearby_stops_data}

        _ ->
          {stop_data, [data | nearby_stops_data]}
      end
    end)
  end

  @degrees_to_radians 0.0174533
  @twice_earth_radius_miles 7918

  @doc "Returns the Haversine distance (in miles) between two latitude/longitude pairs"
  @spec distance(number, number, number, number) :: float
  def distance(latitude, longitude, latitude2, longitude2) do
    # Haversine distance
    a =
      0.5 - :math.cos((latitude2 - latitude) * @degrees_to_radians) / 2 +
        :math.cos(latitude * @degrees_to_radians) * :math.cos(latitude2 * @degrees_to_radians) *
          (1 - :math.cos((longitude2 - longitude) * @degrees_to_radians)) / 2

    @twice_earth_radius_miles * :math.asin(:math.sqrt(a))
  end
end
