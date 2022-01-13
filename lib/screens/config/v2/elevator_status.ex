defmodule Screens.Config.V2.ElevatorStatus do
  @moduledoc false

  @type t :: %__MODULE__{
          parent_station_id: String.t()
        }

  @enforce_keys [:parent_station_id]
  defstruct parent_station_id: nil

  use Screens.Config.Struct

  defp value_from_json(_, value), do: value

  defp value_to_json(_, value), do: value
end
