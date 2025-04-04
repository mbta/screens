defmodule Screens.Facilities.Parser do
  @moduledoc false

  alias Screens.Facilities.Facility
  alias Screens.V3Api

  def parse(
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
          "relationships" => %{"stop" => stop}
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
      stop: V3Api.Parser.included(stop, included, :unloaded),
      type: type |> String.downcase() |> String.to_existing_atom()
    }
  end

  defp excluded_stop_id(%{"name" => "excludes-stop", "value" => id}), do: [to_string(id)]
  defp excluded_stop_id(_property), do: []
end
