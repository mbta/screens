defmodule Screens.Config.Solari.Section.Layout.Upcoming do
  @moduledoc false

  alias Screens.Config.Solari.Section.Layout.RouteConfig
  alias Screens.Util

  @type t :: %__MODULE__{
          num_rows: pos_integer() | :infinity,
          paged: boolean(),
          visible_rows: pos_integer() | :infinity,
          routes: RouteConfig.t(),
          max_minutes: pos_integer() | :infinity
        }

  defstruct num_rows: 1,
            paged: false,
            visible_rows: 1,
            routes: RouteConfig.from_json(:default),
            max_minutes: :infinity

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

  for key <- ~w[num_rows visible_rows max_minutes]a do
    key_string = Atom.to_string(key)

    defp value_from_json(unquote(key_string), "infinity"), do: :infinity

    defp value_to_json(unquote(key), :infinity), do: "infinity"
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
