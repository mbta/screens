defmodule Screens.Trips.Trip do
  @moduledoc false

  defstruct id: nil,
            headsign: nil

  @type id :: String.t()

  @type t :: %__MODULE__{
          id: id,
          headsign: String.t()
        }
end
