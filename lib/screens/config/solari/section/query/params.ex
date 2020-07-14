defmodule Screens.Config.Solari.Section.Query.Params do
  @type t :: %__MODULE__{
          stop_ids: list(String.t()),
          route_ids: list(String.t()),
          direction_id: 0 | 1 | :both
        }

  @default_direction_id :both

  defstruct stop_ids: [],
            route_ids: [],
            direction_id: @default_direction_id

  @spec from_json(map() | :default) :: t()
  def from_json(%{} = json) do
    stop_ids = Map.get(json, "stop_ids", [])
    route_ids = Map.get(json, "route_ids", [])
    direction_id = Map.get(json, "direction_id", :default)

    %__MODULE__{
      stop_ids: stop_ids,
      route_ids: route_ids,
      direction_id: direction_id_from_json(direction_id)
    }
  end

  def from_json(:default) do
    %__MODULE__{}
  end

  @spec to_json(t()) :: map()
  def to_json(%__MODULE__{stop_ids: stop_ids, route_ids: route_ids, direction_id: direction_id}) do
    %{
      "stop_ids" => stop_ids,
      "route_ids" => route_ids,
      "direction_id" => direction_id_to_json(direction_id)
    }
  end

  defp direction_id_from_json(0), do: 0
  defp direction_id_from_json(1), do: 1
  defp direction_id_from_json(_), do: @default_direction_id

  defp direction_id_to_json(:both), do: "both"
  defp direction_id_to_json(id) when is_integer(id), do: id
end
