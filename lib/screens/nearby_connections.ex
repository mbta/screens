defmodule Screens.NearbyConnections do
  @moduledoc false

  alias Screens.Config.{Bus, State}

  def by_screen_id(screen_id) do
    %Bus{stop_id: stop_id, nearby_connections: nearby_connections} = State.app_params(screen_id)

    nearby_stop_ids = Enum.map(nearby_connections, fn {stop_id, _} -> stop_id end)
    stop_query = Enum.join([stop_id | nearby_stop_ids], ",")

    case Screens.V3Api.get_json("stops", %{"filter[id]" => stop_query}) do
      {:ok, %{"data" => stops_data}} ->
        result =
          stops_data
          |> Enum.map(&parse_stop_data/1)
          |> build_nearby_connections(stop_id, nearby_connections)

        {:ok, result}

      _ ->
        :error
    end
  end

  def parse_stop_data(%{
        "attributes" => %{"latitude" => lat, "longitude" => lon, "name" => name},
        "id" => id
      }) do
    %{stop_id: id, stop_name: name, stop_lat: lat, stop_lon: lon}
  end

  def build_nearby_connections(stops_data, stop_id, routes_at_stops) do
    {stop_data, nearby_stops_data} = split_stops_data(stops_data, stop_id)
    %{stop_lat: stop_lat, stop_lon: stop_lon} = stop_data

    nearby_connections =
      nearby_stops_data
      |> Enum.map(&build_nearby_connection(&1, stop_lat, stop_lon, routes_at_stops))
      |> Enum.sort_by(& &1.distance)
      |> Enum.map(&convert_distance/1)

    {stop_data, nearby_connections}
  end

  @miles_to_feet 5280
  @feet_to_minutes 1 / 250

  defp convert_distance(%{distance: distance_miles} = connection) do
    distance_minutes = max(1, Kernel.round(distance_miles * @miles_to_feet * @feet_to_minutes))
    %{connection | distance: distance_minutes}
  end

  def build_nearby_connection(
        %{stop_lat: nearby_lat, stop_lon: nearby_lon, stop_name: name, stop_id: nearby_id},
        stop_lat,
        stop_lon,
        routes_at_stops
      ) do
    distance_miles = distance(stop_lat, stop_lon, nearby_lat, nearby_lon)
    routes_at_stop = routes_at_stops |> Enum.into(%{}) |> Map.get(nearby_id)
    %{name: name, distance: distance_miles, routes: routes_at_stop}
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
