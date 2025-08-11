defmodule Screens.Routes.Parser do
  @moduledoc false

  alias Screens.{Routes, RouteType, V3Api}

  def parse(
        %{
          "id" => id,
          "attributes" => %{
            "short_name" => short_name,
            "long_name" => long_name,
            "direction_names" => direction_names,
            "direction_destinations" => direction_destinations,
            "type" => route_type
          },
          "relationships" => %{"line" => line}
        },
        included
      ) do
    %Routes.Route{
      id: id,
      short_name: short_name,
      long_name: long_name,
      direction_names: direction_names,
      direction_destinations: direction_destinations,
      type: RouteType.from_id(route_type),
      line: V3Api.Parser.included!(line, included)
    }
  end
end
