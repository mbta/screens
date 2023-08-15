defmodule Screens.Config.V2.Triptych do
  @moduledoc false

  alias Screens.Config.V2.{EvergreenContentItem, TrainCrowding}

  @type t :: %__MODULE__{
          train_crowding: TrainCrowding.t(),
          evergreen_content: list(EvergreenContentItem.t())
        }

  defstruct train_crowding: nil,
            evergreen_content: []

  use Screens.Config.Struct,
    children: [train_crowding: TrainCrowding, evergreen_content: {:list, EvergreenContentItem}]
end
