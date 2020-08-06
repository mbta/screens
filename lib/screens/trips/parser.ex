defmodule Screens.Trips.Parser do
  @moduledoc false

  def parse_trip(%{"id" => id, "attributes" => attributes, "relationships" => relationships}) do
    %{"headsign" => headsign, "direction_id" => direction_id} = attributes
    %{"route" => %{"data" => %{"id" => route_id}}} = relationships

    stops =
      case Map.get(relationships, "stops") do
        %{"data" => stop_list} ->
          Enum.map(stop_list, fn %{"id" => stop_id, "type" => "stop"} -> stop_id end)

        _ ->
          nil
      end

    %Screens.Trips.Trip{
      id: id,
      direction_id: direction_id,
      headsign: headsign,
      route_id: route_id,
      stops: stops
    }
  end
end
