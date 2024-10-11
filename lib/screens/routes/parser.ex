defmodule Screens.Routes.Parser do
  @moduledoc false

  alias Screens.{Lines, Routes, RouteType}

  def parse(%{"data" => data} = response) do
    included =
      response
      |> Map.get("included", [])
      |> Map.new(fn %{"id" => id, "type" => type} = resource -> {{id, type}, resource} end)

    Enum.map(data, &parse_route(&1, included))
  end

  def parse_route(
        %{
          "id" => id,
          "attributes" => %{
            "short_name" => short_name,
            "long_name" => long_name,
            "direction_destinations" => direction_destinations,
            "type" => route_type
          },
          "relationships" => %{"line" => %{"data" => %{"id" => line_id}}}
        },
        included
      ) do
    %Routes.Route{
      id: id,
      short_name: short_name,
      long_name: long_name,
      direction_destinations: direction_destinations,
      type: RouteType.from_id(route_type),
      line: included |> Map.fetch!({line_id, "line"}) |> Lines.Parser.parse_line()
    }
  end
end
