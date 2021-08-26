defmodule Screens.Config.V2.BusShelter do
  @moduledoc false
  # credo:disable-for-this-file Credo.Check.Design.DuplicatedCode

  alias Screens.Config.V2.{Alerts, Departures, EvergreenContentItem, Footer, Survey}
  alias Screens.Config.V2.Header.CurrentStopId

  @type t :: %__MODULE__{
          departures: Departures.t(),
          footer: Footer.t(),
          header: CurrentStopId.t(),
          alerts: Alerts.t(),
          evergreen_content: list(EvergreenContentItem.t()),
          survey: Survey.t()
        }

  @enforce_keys [:departures, :footer, :header, :alerts]
  defstruct departures: nil,
            footer: nil,
            header: nil,
            alerts: nil,
            evergreen_content: [],
            survey: Survey.from_json(:default)

  use Screens.Config.Struct,
    children: [
      departures: Departures,
      footer: Footer,
      header: CurrentStopId,
      alerts: Alerts,
      evergreen_content: {:list, EvergreenContentItem},
      survey: Survey
    ]
end
