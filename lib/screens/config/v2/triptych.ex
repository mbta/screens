defmodule Screens.Config.V2.Triptych do
  @moduledoc false

  alias Screens.Config.V2.{EvergreenContentItem, OLCrowding}

  @type t :: %__MODULE__{
          ol_crowding: OLCrowding.t(),
          evergreen_content: list(EvergreenContentItem.t())
        }

  defstruct ol_crowding: nil,
            evergreen_content: []

  use Screens.Config.Struct,
    children: [ol_crowding: OLCrowding, evergreen_content: {:list, EvergreenContentItem}]
end
