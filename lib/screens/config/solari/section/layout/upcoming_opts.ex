defmodule Screens.Config.Solari.Section.Layout.UpcomingOpts do
  alias Screens.Config.Solari.Section.Layout.RouteConfig

  @type t :: %__MODULE__{
          num_rows: pos_integer(),
          paged: boolean(),
          visible_rows: pos_integer(),
          routes: RouteConfig.t(),
          max_minutes: pos_integer()
        }

  defstruct num_rows: 1,
            paged: false,
            visible_rows: 1,
            routes: RouteConfig.from_json(:default),
            max_minutes: 1

  @spec from_json(map() | :default) :: t()
  def from_json(%{} = json) do
    primitives = Enum.reduce(json, %{}, &add_key_from_json/2)

    routes = Map.get(json, "routes", :default)

    struct(__MODULE__, Map.merge(primitives, routes))
  end

  def from_json(:default) do
    %__MODULE__{}
  end

  @spec to_json(t()) :: map()
  def to_json(%__MODULE__{
        num_rows: num_rows,
        paged: paged,
        visible_rows: visible_rows,
        routes: routes,
        max_minutes: max_minutes
      }) do
    %{
      "num_rows" => num_rows,
      "paged" => paged,
      "visible_rows" => visible_rows,
      "routes" => RouteConfig.to_json(routes),
      "max_minutes" => max_minutes
    }
  end

  for primitive_key <- ~w[num_rows paged visible_rows max_minutes]a do
    primitive_key_string = Atom.to_string(primitive_key)

    defp add_key_from_json(map, {unquote(primitive_key_string), value}) do
      Map.put(map, unquote(primitive_key), value)
    end
  end

  defp add_key_from_json(map, _) do
    map
  end
end
