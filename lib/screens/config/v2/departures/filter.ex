defmodule Screens.Config.V2.Departures.Filter do
  @moduledoc false

  alias Screens.Config.V2.Departures.Filter.RouteDirection
  alias Screens.Util

  @type t :: %__MODULE__{
          action: :include | :exclude,
          route_directions: list(RouteDirection.t())
        }

  @enforce_keys [:action]
  defstruct action: nil,
            route_directions: []

  @spec from_json(map()) :: t()
  def from_json(%{} = json) do
    struct_map =
      json
      |> Map.take(Util.struct_keys(__MODULE__))
      |> Enum.into(%{}, fn {k, v} -> {String.to_existing_atom(k), value_from_json(k, v)} end)

    struct!(__MODULE__, struct_map)
  end

  defp value_from_json("action", "include"), do: :include
  defp value_from_json("action", "exclude"), do: :exclude

  defp value_from_json("route_directions", route_directions) do
    Enum.map(route_directions, &RouteDirection.to_json/1)
  end

  @spec to_json(t()) :: map()
  def to_json(%__MODULE__{} = t) do
    t
    |> Map.from_struct()
    |> Enum.into(%{}, fn {k, v} -> {k, value_to_json(k, v)} end)
  end

  defp value_to_json(:route_directions, route_directions) do
    Enum.map(route_directions, &RouteDirection.from_json/1)
  end

  defp value_to_json(_, value), do: value
end
