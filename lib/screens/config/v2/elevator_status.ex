defmodule Screens.Config.V2.ElevatorStatus do
  @moduledoc false

  @type t :: %__MODULE__{
          parent_station_id: String.t(),
          platform_stop_ids: list(String.t())
        }

  @enforce_keys [:parent_station_id, :platform_stop_ids]
  defstruct parent_station_id: nil,
            platform_stop_ids: nil

  use Screens.Config.Struct

  defp value_from_json(_, value), do: value

  defp value_to_json(_, value), do: value
end
