defmodule Screens.Config.V2.PreFare do
  @moduledoc false

  alias Screens.Config.V2.ElevatorStatus
  alias Screens.Config.V2.Header.CurrentStopId

  @type t :: %__MODULE__{
          header: CurrentStopId.t(),
          elevator_status: ElevatorStatus.t()
        }

  @enforce_keys [:header, :elevator_status]
  defstruct header: nil,
            elevator_status: nil

  use Screens.Config.Struct,
    children: [
      elevator_status: ElevatorStatus,
      header: CurrentStopId
    ]
end
