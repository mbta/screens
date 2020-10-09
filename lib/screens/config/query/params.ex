defmodule Screens.Config.Query.Params do
  @moduledoc false

  alias Screens.Util

  @type t :: %__MODULE__{
          stop_ids: list(String.t()),
          route_ids: list(String.t()),
          direction_id: 0 | 1 | :both,
          route_type: route_type
        }

  @type route_type :: :light_rail | :subway | :rail | :bus | :ferry | :all

  defstruct stop_ids: [],
            route_ids: [],
            direction_id: :both,
            route_type: :all

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

  for route_type <- ~w[light_rail subway rail bus ferry all]a do
    route_type_string = Atom.to_string(route_type)

    defp value_from_json("route_type", unquote(route_type_string)) do
      unquote(route_type)
    end

    defp value_to_json(:route_type, unquote(route_type)) do
      unquote(route_type_string)
    end
  end

  defp value_from_json(_, value), do: value

  defp value_to_json(_, value), do: value
end
