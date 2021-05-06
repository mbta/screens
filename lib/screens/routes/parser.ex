defmodule Screens.Routes.Parser do
  @moduledoc false

  def parse_route(%{
        "id" => id,
        "attributes" => %{
          "short_name" => short_name,
          "direction_destinations" => direction_destinations,
          "type" => route_type
        }
      }) do
    %Screens.Routes.Route{
      id: id,
      short_name: short_name,
      direction_destinations: direction_destinations,
      type: Screens.RouteType.from_id(route_type)
    }
  end
end
