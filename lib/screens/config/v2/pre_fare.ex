defmodule Screens.Config.V2.PreFare do
  @moduledoc false

  alias Screens.Config.V2.{ElevatorStatus, EvergreenContentItem, FullLineMap}
  alias Screens.Config.V2.Header.CurrentStopName

  @type t :: %__MODULE__{
          header: CurrentStopName.t(),
          elevator_status: ElevatorStatus.t(),
          evergreen_content: list(EvergreenContentItem.t()),
          full_line_map: list(FullLineMap.t())
        }

  @enforce_keys [:header, :elevator_status, :full_line_map]
  defstruct header: nil,
            elevator_status: nil,
            full_line_map: [],
            evergreen_content: []

  use Screens.Config.Struct,
    children: [
      elevator_status: ElevatorStatus,
      full_line_map: {:list, FullLineMap},
      evergreen_content: {:list, EvergreenContentItem},
      header: CurrentStopName
    ]
end
