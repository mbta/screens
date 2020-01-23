defmodule Screens.Trips.Parser do
  @moduledoc false

  def parse_trip(%{"id" => id, "attributes" => %{"headsign" => headsign}}) do
    %Screens.Trips.Trip{
      id: id,
      headsign: headsign
    }
  end
end
