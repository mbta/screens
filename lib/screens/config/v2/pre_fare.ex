defmodule Screens.Config.V2.PreFare do
  @moduledoc false

  alias Screens.Config.V2.{
    Audio,
    BlueBikes,
    ContentSummary,
    CRDepartures,
    OvernightCRDepartures,
    ElevatorStatus,
    EvergreenContentItem,
    FullLineMap,
    ShuttleBusInfo
  }

  alias Screens.Config.V2.Header.CurrentStopId

  @type t :: %__MODULE__{
          header: CurrentStopId.t(),
          reconstructed_alert_widget: CurrentStopId.t(),
          elevator_status: ElevatorStatus.t(),
          full_line_map: list(FullLineMap.t()),
          evergreen_content: list(EvergreenContentItem.t()),
          blue_bikes: BlueBikes.t(),
          content_summary: ContentSummary.t(),
          audio: Audio.t(),
          cr_departures: CRDepartures.t(),
          overnight_cr_departures: OvernightCRDepartures.t(),
          shuttle_bus_info: ShuttleBusInfo.t()
        }

  @enforce_keys [
    :header,
    :reconstructed_alert_widget,
    :elevator_status,
    :full_line_map,
    :content_summary
  ]
  defstruct header: nil,
            reconstructed_alert_widget: nil,
            elevator_status: nil,
            full_line_map: [],
            evergreen_content: [],
            blue_bikes: BlueBikes.from_json(:default),
            content_summary: nil,
            audio: Audio.from_json(:default),
            cr_departures: CRDepartures.from_json(:default),
            overnight_cr_departures: OvernightCRDepartures.from_json(:default),
            shuttle_bus_info: ShuttleBusInfo.from_json(:default)

  use Screens.Config.Struct,
    children: [
      header: CurrentStopId,
      elevator_status: ElevatorStatus,
      full_line_map: {:list, FullLineMap},
      evergreen_content: {:list, EvergreenContentItem},
      blue_bikes: BlueBikes,
      reconstructed_alert_widget: CurrentStopId,
      content_summary: ContentSummary,
      audio: Audio,
      cr_departures: CRDepartures,
      overnight_cr_departures: OvernightCRDepartures,
      shuttle_bus_info: ShuttleBusInfo
    ]
end
