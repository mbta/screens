defmodule Screens.Config.V2.Triptych do
  @moduledoc false

  alias Screens.Config.V2.{EvergreenContentItem, LocalEvergreenSet, TrainCrowding}

  @type t :: %__MODULE__{
          train_crowding: TrainCrowding.t(),
          local_evergreen_set: list(LocalEvergreenSet.t()),
          evergreen_content: list(EvergreenContentItem.t())
        }

  @enforce_keys [:train_crowding, :local_evergreen_set]
  defstruct train_crowding: nil,
            local_evergreen_set: [],
            evergreen_content: []

  use Screens.Config.Struct,
    children: [
      train_crowding: TrainCrowding,
      local_evergreen_set: {:list, LocalEvergreenSet},
      evergreen_content: {:list, EvergreenContentItem}
    ]
end
