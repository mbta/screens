defmodule Screens.Config.V2.PreFare do
  @moduledoc false

  alias Screens.Config.V2.{ElevatorStatus, PreFareLineMap}

  @type t :: %__MODULE__{
          elevator_status: ElevatorStatus.t(),
          pre_fare_line_map: list(PreFareLineMap.t())
        }

  @enforce_keys [:elevator_status, :pre_fare_line_map]
  defstruct elevator_status: nil,
            pre_fare_line_map: []

  use Screens.Config.Struct,
    children: [
      elevator_status: ElevatorStatus,
      pre_fare_line_map: {:list, PreFareLineMap}
    ]
end
