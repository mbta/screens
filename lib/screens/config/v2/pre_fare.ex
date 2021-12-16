defmodule Screens.Config.V2.PreFare do
  @moduledoc false

  alias Screens.Config.V2.Header.CurrentStopName

  @type t :: %__MODULE__{
          header: CurrentStopName.t()
        }

  use Screens.Config.Struct
end
