defmodule Screens.Trips.Trip do
  @moduledoc false

  alias Screens.Stops.Stop

  defstruct ~w[id direction_id headsign pattern_headsign route_id stops]a

  @type id :: String.t()
  @type direction :: 0 | 1

  @type t :: %__MODULE__{
          id: id,
          direction_id: direction(),
          headsign: String.t(),
          pattern_headsign: String.t() | nil,
          route_id: String.t() | nil,
          stops: list(Stop.id()) | nil
        }

  @spec representative_headsign(t()) :: String.t()
  def representative_headsign(%__MODULE__{pattern_headsign: headsign}) when not is_nil(headsign),
    do: headsign

  def representative_headsign(%__MODULE__{headsign: headsign}), do: headsign
end
