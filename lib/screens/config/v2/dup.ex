defmodule Screens.Config.V2.Dup do
  @moduledoc false

  alias Screens.Config.V2.Header.CurrentStopId
  alias Screens.Config.V2.{Alerts, Departures, EvergreenContentItem}

  @type t :: %__MODULE__{
          header: CurrentStopId.t(),
          primary_departures: Departures.t(),
          secondary_departures: Departures.t(),
          alerts: Alerts.t(),
          evergreen_content: list(EvergreenContentItem.t())
        }

  @enforce_keys [:header, :primary_departures, :secondary_departures, :alerts]
  defstruct @enforce_keys ++ [evergreen_content: []]

  use Screens.Config.Struct,
    children: [
      header: CurrentStopId,
      primary_departures: Departures,
      secondary_departures: Departures,
      alerts: Alerts,
      evergreen_content: {:list, EvergreenContentItem}
    ]
end
