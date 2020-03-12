defmodule Screens.Stops.Stop do
  @moduledoc false

  defstruct id: nil,
            name: nil

  @type id :: String.t()

  @type t :: %__MODULE__{
          id: id,
          name: String.t()
        }
end
