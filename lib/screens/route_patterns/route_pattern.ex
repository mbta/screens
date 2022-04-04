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
        route_filters \\ [],
        get_json_fn \\ &V3Api.get_json/2
      ) do
    params = %{
      "include" => "representative_trip.stops,route",
      "filter[stop]" => stop_id
    }

    params =
      if length(route_filters) > 0 do
        Map.put(params, "filter[route]", Enum.join(route_filters, ","))
      else
        params
      end

    case get_json_fn.("route_patterns", params) do
      {:ok, result} ->
        {:ok, get_stop_sequences_from_result(result)}

      _ ->
        :error
    end
  end

  @doc """
  Gets the list of stop sequences for stop and creates a map of platform IDs to parent station name.
  Assumes that all stop sequences in result are platforms.
  """
  @spec fetch_parent_station_sequences_through_stop(Stop.id(), list(String.t())) ::
          {:ok, list(list(Stop.id())), map()} | :error
  def fetch_parent_station_sequences_through_stop(
        stop_id,
        route_filters,
        get_json_fn \\ &V3Api.get_json/2
      ) do
    params = %{
      "include" => "representative_trip.stops,route",
      "filter[stop]" => stop_id,
      "filter[route]" => Enum.join(route_filters, ",")
    }

    case get_json_fn.("route_patterns", params) do
      {:ok, result} ->
        {:ok, convert_platform_to_parent_station(result)}

      _ ->
        :error
    end
  end

  defp get_stop_sequences_from_result(result) do
    get_in(result, [
      "included",
      Access.filter(&(&1["type"] == "trip")),
      "relationships",
      "stops",
      "data",
      Access.all(),
      "id"
    ])
  end

  defp get_platform_to_station_map_from_result(result) do
    result
    |> get_in([
      "included",
      Access.filter(&(&1["type"] == "stop"))
    ])
    |> Enum.map(fn %{
                     "relationships" => %{
                       "parent_station" => %{"data" => %{"id" => parent_station_name}}
                     },
                     "id" => platform_id
                   } ->
      {platform_id, parent_station_name}
    end)
    |> Enum.into(%{})
  end

  defp convert_platform_to_parent_station(result) do
    platform_to_station_map = get_platform_to_station_map_from_result(result)

    result
    |> get_stop_sequences_from_result()
    |> Enum.map(fn stop_sequence ->
      stop_sequence
      |> Enum.map(&Map.fetch!(platform_to_station_map, &1))
    end)
    # Dedup the stop sequences (both directions are listed, but we only need 1)
    |> Enum.uniq_by(&MapSet.new/1)
  end
end
