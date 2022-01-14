defmodule Screens.Config.V2.PreFare do
  @moduledoc false

  alias Screens.Config.V2.ElevatorStatus

  @type t :: %__MODULE__{
          elevator_status: ElevatorStatus.t()
        }

  @enforce_keys [:elevator_status]
  defstruct elevator_status: nil

  use Screens.Config.Struct,
    children: [
      elevator_status: ElevatorStatus
    ]
end
