defmodule Screens.RoutePatterns.Parser do
  @moduledoc false

  require Logger

  def parse_result(%{"data" => data, "included" => included}, route_id) do
    included_data = parse_included_data(included)
    parse_data(data, included_data, route_id)
  end

  def parse_result(_, _) do
    Logger.warn("Unrecognized format of route_pattern data.")
    :error
  end

  defp parse_included_data(data) do
    data
    |> Enum.map(fn item ->
      {{Map.get(item, "type"), Map.get(item, "id")}, parse_included(item)}
    end)
    |> Enum.into(%{})
  end

  defp parse_included(%{"type" => "stop"} = item) do
    Screens.Stops.Parser.parse_stop(item)
  end

  defp parse_included(%{
         "type" => "trip",
         "relationships" => %{"stops" => %{"data" => stops_data}}
       }) do
    Enum.map(stops_data, &parse_stop_data/1)
  end

  defp parse_stop_data(%{"id" => stop_id, "type" => "stop"}) do
    stop_id
  end

  defp parse_data(data, included_data, route_id) do
    filtered_data = filter_by_route(data, route_id)
    [typical_data | _] = filtered_data
    parse_route_pattern(typical_data, included_data)
  end

  defp filter_by_route(data, route_id) do
    Enum.filter(data, &has_related_route(&1, route_id))
  end

  defp has_related_route(%{"relationships" => %{"route" => %{"data" => %{"id" => id}}}}, route_id) do
    route_id == id
  end

  defp has_related_route(_, _route_id) do
    false
  end

  defp parse_route_pattern(
         %{
           "relationships" => %{
             "representative_trip" => %{"data" => %{"id" => trip_id, "type" => "trip"}}
           }
         },
         included_data
       ) do
    # The only way this function output an empty array is if the trip data has an empty stop list
    # This happens occasionally in dev-green
    parsed = included_data
    |> Map.get({"trip", trip_id})
    |> Enum.map(fn stop_id -> Map.get(included_data, {"stop", stop_id}) end)

    case parsed do
      # If `trip` is present, but the stop array is empty, there's a problem with the trip in the API
      [] -> 
        Logger.warn("Trip data doesn't contain stop ids. trip_id: #{trip_id}")
        :error
      _ -> parsed
    end
  end
end
