defmodule Screens.RoutePatterns.Parser do
  @moduledoc false

  alias Screens.RoutePatterns.RoutePattern
  alias Screens.V3Api

  def parse(
        %{
          "id" => id,
          "attributes" => %{
            "canonical" => canonical?,
            "direction_id" => direction_id,
            "typicality" => typicality
          },
          "relationships" => %{
            "route" => route,
            "representative_trip" => %{"data" => %{"id" => representative_trip_id}}
          }
        },
        included
      ) do
    %{
      "attributes" => %{"headsign" => headsign},
      "relationships" => %{"stops" => stops}
    } = Map.fetch!(included, {representative_trip_id, "trip"})

    %RoutePattern{
      id: id,
      canonical?: canonical?,
      direction_id: direction_id,
      headsign: headsign,
      route: V3Api.Parser.included!(route, included),
      stops: V3Api.Parser.included!(stops, included),
      typicality: typicality
    }
  end
end
