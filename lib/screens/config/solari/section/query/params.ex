defmodule Screens.Config.Solari.Section.Query.Params do
  alias Screens.Util

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
    struct_map =
      json
      |> Map.take(Util.struct_keys(__MODULE__))
      |> Enum.into(%{}, fn {k, v} -> {String.to_existing_atom(k), value_from_json(k, v)} end)

    struct!(__MODULE__, struct_map)
  end

  def from_json(:default) do
    %__MODULE__{}
  end

  @spec to_json(t()) :: map()
  def to_json(%__MODULE__{} = t) do
    t
    |> Map.from_struct()
    |> Enum.into(%{}, fn {k, v} -> {k, value_to_json(k, v)} end)
  end

  defp value_from_json("direction_id", "both"), do: :both

  defp value_from_json(_, value), do: value

  defp value_to_json(_, value), do: value
end
