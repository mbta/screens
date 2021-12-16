defmodule Screens.Config.V2.PreFare do
  @moduledoc false

  alias Screens.Config.V2.Header.CurrentStopName

  @type t :: %__MODULE__{
          header: CurrentStopName.t()
        }

  @enforce_keys [:header]
  defstruct header: nil

  use Screens.Config.Struct,
    children: [
      header: CurrentStopName
    ]
end
