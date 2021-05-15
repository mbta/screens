defmodule Screens.Config.V2.Departures.Filter.RouteDirection do
  @moduledoc false

  @type t :: %__MODULE__{
          route_id: String.t(),
          direction_id: 0 | 1 | nil
        }

  @enforce_keys [:route_id]
  defstruct route_id: nil,
            direction_id: nil

  use Screens.Config.Struct

  defp value_from_json(_, value), do: value

  defp value_to_json(_, value), do: value
end
