defmodule Screens.Config.V2.PreFare do
  @moduledoc false

  alias Screens.Config.V2.{ElevatorStatus, FullLineMap}

  @type t :: %__MODULE__{
          elevator_status: ElevatorStatus.t(),
          full_line_map: list(FullLineMap.t())
        }

  @enforce_keys [:elevator_status, :full_line_map]
  defstruct elevator_status: nil,
            full_line_map: []

  use Screens.Config.Struct,
    children: [
      elevator_status: ElevatorStatus,
      full_line_map: {:list, FullLineMap}
    ]
end
