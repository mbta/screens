defmodule Screens.Trips.Parser do
  @moduledoc false

  def parse_trip(%{
        "id" => id,
        "attributes" => %{"headsign" => headsign, "direction_id" => direction_id},
        "relationships" => %{"route" => %{"data" => %{"id" => route_id}}}
      }) do
    %Screens.Trips.Trip{
      id: id,
      direction_id: direction_id,
      headsign: headsign,
      route_id: route_id
    }
  end
end
