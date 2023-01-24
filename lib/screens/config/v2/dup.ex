defmodule Screens.Config.V2.Dup do
  @moduledoc false

  alias Screens.Config.V2.Header.CurrentStopId
  alias Screens.Config.V2.{Departures, EvergreenContentItem}

  @type t :: %__MODULE__{
          header: CurrentStopId.t(),
          evergreen_content: list(EvergreenContentItem.t()),
          primary_departures: Departures.t(),
          secondary_departures: Departures.t()
        }

  @enforce_keys [:primary_departures, :secondary_departures, :header]
  defstruct primary_departures: nil,
            secondary_departures: nil,
            header: nil,
            evergreen_content: []

  use Screens.Config.Struct,
    children: [
      primary_departures: Departures,
      secondary_departures: Departures,
      header: CurrentStopId,
      evergreen_content: {:list, EvergreenContentItem}
    ]
end
