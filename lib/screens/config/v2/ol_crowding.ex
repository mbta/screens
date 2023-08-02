defmodule Screens.Config.V2.OLCrowding do
  @moduledoc false
  alias Screens.Config.V2.Header.CurrentStopName

  @type t :: %__MODULE__{
          station: CurrentStopName.t()
        }

  @enforce_keys [:station]
  defstruct station: nil

  use Screens.Config.Struct, children: [station: CurrentStopName]
end
