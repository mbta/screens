defmodule Screens.Stops.Stop do
  @moduledoc false

  defstruct id: nil,
            name: nil

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t()
        }
end
