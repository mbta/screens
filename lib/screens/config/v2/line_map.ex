defmodule Screens.Config.V2.LineMap do
  @moduledoc false

  @type t :: %__MODULE__{
          stop_id: Screens.Stops.Stop.id(),
          station_id: Screens.Stops.Stop.id(),
          direction_id: 0 | 1,
          route_id: Screens.Routes.Route.id()
        }

  @enforce_keys [:stop_id, :station_id, :direction_id, :route_id]
  defstruct stop_id: nil,
            station_id: nil,
            direction_id: nil,
            route_id: nil

  use Screens.Config.Struct

  defp value_from_json(_, value), do: value

  defp value_to_json(_, value), do: value
end
