defmodule Screens.Config.V2.PreFare do
  @moduledoc false

  alias Screens.Config.V2.{ElevatorStatus, EvergreenContentItem}

  @type t :: %__MODULE__{
          elevator_status: ElevatorStatus.t(),
          evergreen_content: list(EvergreenContentItem.t())
        }

  @enforce_keys [:elevator_status]
  defstruct elevator_status: nil, evergreen_content: []

  use Screens.Config.Struct,
    children: [
      elevator_status: ElevatorStatus,
      evergreen_content: {:list, EvergreenContentItem}
    ]
end
