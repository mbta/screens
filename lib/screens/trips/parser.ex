defmodule Screens.Trips.Parser do
  @moduledoc false

  alias Screens.Trips.Trip

  def parse(
        %{
          "id" => id,
          "attributes" => %{"headsign" => headsign, "direction_id" => direction_id},
          "relationships" => %{"route" => %{"data" => %{"id" => route_id}}} = relationships
        },
        included
      ) do
    # We do not fully parse the trip => route_pattern => representative_trip chain, as this would
    # recurse infinitely. Instead we hoist up only the attributes we're interested in.
    pattern_headsign =
      case Map.get(relationships, "route_pattern") do
        %{
          "data" => %{
            "relationships" => %{
              "representative_trip" => %{"data" => %{"id" => representative_trip_id}}
            }
          }
        } ->
          included
          |> Map.fetch!({representative_trip_id, "trip"})
          |> Map.fetch!("attributes")
          |> Map.fetch!("headsign")

        _ ->
          nil
      end

    stops =
      case Map.get(relationships, "stops") do
        %{"data" => stops_data} ->
          Enum.map(stops_data, fn %{"id" => stop_id, "type" => "stop"} -> stop_id end)

        _ ->
          nil
      end

    %Trip{
      id: id,
      direction_id: direction_id,
      headsign: headsign,
      pattern_headsign: pattern_headsign,
      route_id: route_id,
      stops: stops
    }
  end
end
