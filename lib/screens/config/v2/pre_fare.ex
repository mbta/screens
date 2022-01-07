defmodule Screens.Config.V2.PreFare do
  @moduledoc false

  @type t :: %__MODULE__{
          station_id: Screens.Stops.Stop.id()
        }

  @enforce_keys [:station_id]
  defstruct station_id: nil

  use Screens.Config.Struct

  defp value_from_json(_, value), do: value

  defp value_to_json(_, value), do: value
end
