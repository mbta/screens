defmodule Screens.Config.Solari.Section.Layout.Bidirectional do
  @moduledoc false

  alias Screens.Config.Solari.Section.Layout.RouteConfig

  @type t :: %__MODULE__{
          routes: RouteConfig.t()
        }

  defstruct routes: RouteConfig.from_json(:default)

  @spec from_json(map() | :default) :: t()
  def from_json(%{} = json) do
    struct_map =
      json
      |> Map.take(~w[routes])
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

  defp value_from_json("routes", routes) do
    RouteConfig.from_json(routes)
  end

  defp value_from_json(_, value), do: value

  defp value_to_json(:routes, routes) do
    RouteConfig.to_json(routes)
  end

  defp value_to_json(_, value), do: value
end
