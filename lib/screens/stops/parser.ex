defmodule Screens.Stops.Parser do
  @moduledoc false

  alias Screens.RouteType

  def parse(%{"data" => data} = response) do
    included =
      response
      |> Map.get("included", [])
      |> Map.new(fn %{"id" => id, "type" => type} = resource -> {{id, type}, resource} end)

    Enum.map(data, &parse_stop(&1, included))
  end

  def parse_stop(
        %{
          "id" => id,
          "attributes" => %{
            "name" => name,
            "location_type" => location_type,
            "platform_code" => platform_code,
            "platform_name" => platform_name,
            "vehicle_type" => vehicle_type
          },
          "relationships" => relationships
        },
        included,
        load_parent_station? \\ true
      ) do
    parent_station =
      case get_in(relationships, ~w[parent_station data id]) do
        nil ->
          nil

        id ->
          data = Map.get(included, {id, "stop"})

          if is_nil(data) or not load_parent_station?,
            # Only non-parent-stations can have a parent station.
            do: if(location_type != 1, do: :unloaded, else: nil),
            else: parse_stop(data, included)
      end

    child_stops =
      case get_in(relationships, ~w[child_stops data]) do
        nil ->
          # Only parent stations can have child stops.
          if location_type == 1, do: :unloaded, else: []

        stop_references ->
          Enum.map(stop_references, fn %{"id" => id} ->
            # Always leave the `parent_station` of stops in `child_stops` unloaded, else parsing
            # would recurse infinitely. This covers the complete "stop family" regardless of where
            # we start. ("parent -> children" or "child -> parent -> all children")
            included |> Map.fetch!({id, "stop"}) |> parse_stop(included, false)
          end)
      end

    %Screens.Stops.Stop{
      id: id,
      name: name,
      location_type: location_type,
      parent_station: parent_station,
      child_stops: child_stops,
      platform_code: platform_code,
      platform_name: platform_name,
      vehicle_type: if(is_nil(vehicle_type), do: nil, else: RouteType.from_id(vehicle_type))
    }
  end
end
