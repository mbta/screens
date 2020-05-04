defmodule Screens.Trips.Parser do
  @moduledoc false

  def parse_trip(%{
        "id" => id,
        "attributes" => %{"headsign" => headsign, "direction_id" => direction_id}
      }) do
    %Screens.Trips.Trip{
      id: id,
      direction_id: direction_id,
      headsign: headsign
    }
  end
end
