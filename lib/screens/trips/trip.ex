defmodule Screens.Trips.Trip do
  @moduledoc false

  defstruct id: nil,
            headsign: nil

  @type t :: %__MODULE__{
          id: String.t(),
          headsign: String.t()
        }
end
