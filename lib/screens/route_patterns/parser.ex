defmodule Screens.RoutePatterns.Parser do
  @moduledoc false

  # def parse_result(%{"data" => data}) do
  #   data
  #   |> Enum.map(&parse_route_pattern/1)
  # end

  # defp parse_route_pattern(%{
  #        "id" => id,
  #        "attributes" => %{"direction_id" => direction_id, "typicality" => typicality},
  #        "relationships" => %{
  #          "representative_trip" => %{"data" => %{"id" => trip_id, "type" => "trip"}},
  #          "route" => %{"data" => %{"id" => route_id, "type" => "route"}}
  #        }
  #      }) do
  #   %Screens.RoutePatterns.RoutePattern{
  #     id: id,
  #     direction_id: direction_id,
  #     typicality: typicality,
  #     route_id: route_id,
  #     representative_trip_id: trip_id
  #   }
  # end

  def parse_result(%{"data" => data, "included" => included}) do
    included_data = parse_included_data(included)
    parse_data(data, included_data)
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

  defp parse_data(data, included_data) do
    [typical_data | _] = data
    parse_route_pattern(typical_data, included_data)
  end

  defp parse_route_pattern(
         %{
           "relationships" => %{
             "representative_trip" => %{"data" => %{"id" => trip_id, "type" => "trip"}}
           }
         },
         included_data
       ) do
    included_data
    |> Map.get({"trip", trip_id})
    |> Enum.map(fn stop_id -> Map.get(included_data, {"stop", stop_id}) end)
  end
end
