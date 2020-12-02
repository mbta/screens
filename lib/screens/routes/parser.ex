defmodule Screens.Routes.Parser do
  @moduledoc false

  def parse_route(%{
        "id" => id,
        "attributes" => %{
          "short_name" => short_name,
          "direction_destinations" => direction_destinations
        },
        "relationships" => relationships
      }) do
    %Screens.Routes.Route{
      id: id,
      short_name: short_name,
      direction_destinations: direction_destinations,
      stop_id: get_in(relationships, ~w[stop data id]),
      line_id: get_in(relationships, ~w[line data id])
    }
  end
end
