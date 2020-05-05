defmodule Screens.Trips.Parser do
  @moduledoc false

  def parse_trip(%{
        "id" => id,
        "attributes" => %{"headsign" => headsign, "direction_id" => direction_id},
        "relationships" => %{"route" => %{"data" => %{"id" => preferred_route_id}}}
      }) do
    %Screens.Trips.Trip{
      id: id,
      direction_id: direction_id,
      headsign: headsign,
      preferred_route_id: preferred_route_id
    }
  end
end
