defmodule Screens.RoutePatterns.RouteDirectionStops do
  @moduledoc false

  alias Screens.Report

  def parse_result(%{"data" => data} = response, route_id) do
    included_data = response |> Map.get("included", []) |> parse_included_data()
    parse_data(data, included_data, route_id)
  end

  defp parse_included_data(data) do
    data
    |> Enum.map(fn item ->
      {{Map.get(item, "type"), Map.get(item, "id")}, parse_included(item)}
    end)
    |> Enum.into(%{})
  end

  defp parse_included(%{"type" => "stop"} = item) do
    Screens.V3Api.Parser.parse_resource(item, %{})
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
    parsed =
      included_data
      |> Map.get({"trip", trip_id})
      |> Enum.map(fn stop_id -> Map.get(included_data, {"stop", stop_id}) end)

    case parsed do
      [] ->
        # Happens sometimes in API dev (only?). If a trip has no stops, there is something wrong
        # with the data.
        Report.warning("route_pattern_empty_stops", trip_id: trip_id)
        :error

      _ ->
        parsed
    end
  end
end
