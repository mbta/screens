defmodule Screens.Facilities.Parser do
  @moduledoc false

  alias Screens.Facilities.Facility
  alias Screens.Stops

  def parse(%{"data" => data} = response) do
    included =
      response
      |> Map.get("included", [])
      |> Map.new(fn %{"id" => id, "type" => type} = resource -> {{id, type}, resource} end)

    cond do
      is_list(data) -> Enum.map(data, &parse_facility(&1, included))
      is_map(data) -> parse_facility(data, included)
    end
  end

  def parse_facility(
        %{
          "id" => id,
          "attributes" => %{
            "latitude" => latitude,
            "longitude" => longitude,
            "long_name" => long_name,
            "short_name" => short_name,
            "properties" => properties,
            "type" => type
          },
          "relationships" => %{"stop" => %{"data" => %{"id" => stop_id}}}
        },
        included
      ) do
    %Facility{
      id: id,
      excludes_stop_ids: Enum.flat_map(properties, &excluded_stop_id/1),
      latitude: latitude,
      longitude: longitude,
      long_name: long_name,
      short_name: short_name,
      stop:
        case Map.get(included, {stop_id, "stop"}) do
          nil -> :unloaded
          stop -> Stops.Parser.parse_stop(stop, included)
        end,
      type: type |> String.downcase() |> String.to_existing_atom()
    }
  end

  defp excluded_stop_id(%{"name" => "excludes-stop", "value" => id}), do: [to_string(id)]
  defp excluded_stop_id(_property), do: []
end
