defmodule Screens.RoutePatterns.Parser do
  @moduledoc false

  alias Screens.RoutePatterns.RoutePattern
  alias Screens.{Routes, Stops}

  def parse(%{"data" => data} = response) do
    included =
      response
      |> Map.get("included", [])
      |> Map.new(fn %{"id" => id, "type" => type} = resource -> {{id, type}, resource} end)

    Enum.map(data, &parse_route_pattern(&1, included))
  end

  defp parse_route_pattern(
         %{
           "id" => id,
           "attributes" => %{
             "canonical" => canonical?,
             "direction_id" => direction_id,
             "typicality" => typicality
           },
           "relationships" => %{
             "route" => %{"data" => %{"id" => route_id}},
             "representative_trip" => %{"data" => %{"id" => representative_trip_id}}
           }
         },
         included
       ) do
    %{
      "attributes" => %{"headsign" => headsign},
      "relationships" => %{"stops" => %{"data" => stop_references}}
    } = Map.fetch!(included, {representative_trip_id, "trip"})

    stops =
      Enum.map(stop_references, fn %{"id" => stop_id} ->
        included |> Map.fetch!({stop_id, "stop"}) |> Stops.Parser.parse_stop(included)
      end)

    %RoutePattern{
      id: id,
      canonical?: canonical?,
      direction_id: direction_id,
      typicality: typicality,
      route: included |> Map.fetch!({route_id, "route"}) |> Routes.Parser.parse_route(included),
      headsign: headsign,
      stops: stops
    }
  end
end
