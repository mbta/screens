defmodule Screens.Stops.Parser do
  @moduledoc false

  alias Screens.RouteType

  def parse(
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
        load_parent_station? \\ true,
        load_connecting_stops? \\ true
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
            else: parse(data, included, load_parent_station?, load_connecting_stops?)
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
            included
            |> Map.fetch!({id, "stop"})
            |> parse(included, false, load_connecting_stops?)
          end)
      end

    connecting_stops =
      if load_connecting_stops? do
        case get_in(relationships, ~w[connecting_stops data]) do
          nil ->
            :unloaded

          stop_references ->
            Enum.map(stop_references, fn %{"id" => id} ->
              # We expect all `connecting_stops` to have no parent station, but leave it unloaded
              # just in case there is one, to avoid infinite recursion. We also prevent connecting
              # stops from loading more connecting stops to prevent another infinite cycle.
              included
              |> Map.fetch!({id, "stop"})
              |> parse(included, false, false)
            end)
        end
      else
        :unloaded
      end

    %Screens.Stops.Stop{
      id: id,
      name: name,
      location_type: location_type,
      parent_station: parent_station,
      child_stops: child_stops,
      connecting_stops: connecting_stops,
      platform_code: platform_code,
      platform_name: platform_name,
      vehicle_type: if(is_nil(vehicle_type), do: nil, else: RouteType.from_id(vehicle_type))
    }
  end
end
