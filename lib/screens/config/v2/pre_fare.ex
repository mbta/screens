defmodule Screens.Config.V2.PreFare do
  @moduledoc false

  alias Screens.Config.V2.{ElevatorStatus, EvergreenContentItem}
  alias Screens.Config.V2.Header.CurrentStopId

  @type t :: %__MODULE__{
          header: CurrentStopId.t(),
          elevator_status: ElevatorStatus.t(),
          evergreen_content: list(EvergreenContentItem.t())
        }

  @enforce_keys [:header, :elevator_status]
  defstruct header: nil, elevator_status: nil, evergreen_content: []

  use Screens.Config.Struct,
    children: [
      elevator_status: ElevatorStatus,
      evergreen_content: {:list, EvergreenContentItem},
      header: CurrentStopId
    ]
end
