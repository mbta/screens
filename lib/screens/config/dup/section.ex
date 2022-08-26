defmodule Screens.Config.Dup.Section do
  @moduledoc false

  alias Screens.Config.Dup.Section.Headway
  alias Screens.RouteType

  @type t :: %__MODULE__{
          stop_ids: list(stop_id()),
          route_ids: list(route_id()),
          route_type: RouteType.t() | nil,
          pill: :bus | :red | :orange | :green | :blue | :cr | :mattapan | :silver | :ferry,
          headway: Headway.t(),
          direction_id: 0 | 1 | nil
        }

  @type stop_id :: String.t()
  @type route_id :: String.t()

  @enforce_keys [:pill]
  defstruct stop_ids: [],
            route_ids: [],
            route_type: nil,
            pill: nil,
            headway: Headway.from_json(:default),
            direction_id: nil

  use Screens.Config.Struct, children: [headway: Headway]

  for pill <- ~w[bus red orange green blue cr mattapan silver ferry]a do
    pill_string = Atom.to_string(pill)

    defp value_from_json("pill", unquote(pill_string)) do
      unquote(pill)
    end
  end

  defp value_from_json("route_type", route_type) when is_binary(route_type) do
    RouteType.from_string(route_type)
  end

  defp value_from_json(_, value), do: value

  defp value_to_json(_, value), do: value
end
