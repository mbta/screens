defmodule Screens.Routes.Parser do
  @moduledoc false

  def parse_route(%{
        "id" => id,
        "attributes" => %{
          "short_name" => short_name,
          "direction_destinations" => direction_destinations
        }
      }) do
    %Screens.Routes.Route{
      id: id,
      short_name: short_name,
      direction_destinations: direction_destinations
    }
  end
end
