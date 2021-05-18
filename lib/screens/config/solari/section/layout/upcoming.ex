defmodule Screens.Config.Solari.Section.Layout.Upcoming do
  @moduledoc false

  alias Screens.Config.Solari.Section.Layout.RouteConfig

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

  use Screens.Config.Struct, with_default: true, children: [routes: RouteConfig]

  for key <- ~w[num_rows visible_rows max_minutes]a do
    key_string = Atom.to_string(key)

    defp value_from_json(unquote(key_string), "infinity"), do: :infinity

    defp value_to_json(unquote(key), :infinity), do: "infinity"
  end

  defp value_from_json(_, value), do: value

  defp value_to_json(_, value), do: value
end
