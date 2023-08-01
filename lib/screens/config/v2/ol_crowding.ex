defmodule Screens.Config.V2.OLCrowding do
  @moduledoc false

  @type t :: %__MODULE__{
          station: CurrentStopName.t()
        }

  @enforce_keys [:station]
  defstruct station: []

  use Screens.Config.Struct
end
