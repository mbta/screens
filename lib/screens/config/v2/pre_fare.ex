defmodule Screens.Config.V2.PreFare do
  @moduledoc false

  alias Screens.Config.V2.{
    Audio,
    ContentSummary,
    ElevatorStatus,
    EvergreenContentItem,
    FullLineMap
  }

  alias Screens.Config.V2.Header.CurrentStopId

  @type t :: %__MODULE__{
          header: CurrentStopId.t(),
          elevator_status: ElevatorStatus.t(),
          full_line_map: list(FullLineMap.t()),
          evergreen_content: list(EvergreenContentItem.t()),
          content_summary: ContentSummary.t(),
          audio: Audio.t()
        }

  @enforce_keys [:header, :elevator_status, :full_line_map, :content_summary]
  defstruct header: nil,
            elevator_status: nil,
            full_line_map: [],
            evergreen_content: [],
            content_summary: nil,
            audio: Audio.from_json(:default)

  use Screens.Config.Struct,
    children: [
      header: CurrentStopId,
      elevator_status: ElevatorStatus,
      full_line_map: {:list, FullLineMap},
      evergreen_content: {:list, EvergreenContentItem},
      content_summary: ContentSummary,
      audio: Audio
    ]
end
