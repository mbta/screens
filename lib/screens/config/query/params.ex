defmodule Screens.Config.Query.Params do
  @moduledoc false
  # credo:disable-for-this-file Credo.Check.Design.DuplicatedCode

  alias Screens.RouteType

  @type t :: %__MODULE__{
          stop_ids: list(String.t()),
          route_ids: list(String.t()),
          direction_id: 0 | 1 | :both,
          route_type: RouteType.t() | nil
        }

  defstruct stop_ids: [],
            route_ids: [],
            direction_id: :both,
            route_type: nil

  use Screens.Config.Struct, with_default: true

  defp value_from_json("direction_id", "both"), do: :both

  defp value_from_json("route_type", route_type) when is_binary(route_type) do
    RouteType.from_string(route_type)
  end

  defp value_from_json(_, value), do: value

  defp value_to_json(_, value), do: value
end
