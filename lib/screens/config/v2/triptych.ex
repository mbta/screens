defmodule Screens.Config.V2.Triptych do
  @moduledoc false

  alias Screens.Config.V2.{EvergreenContentItem, LocalEvergreenSet, TrainCrowding}

  @type t :: %__MODULE__{
          train_crowding: TrainCrowding.t(),
          local_evergreen_sets: list(LocalEvergreenSet.t()),
          evergreen_content: list(EvergreenContentItem.t())
        }

  @enforce_keys [:train_crowding, :local_evergreen_sets]
  defstruct train_crowding: nil,
            local_evergreen_sets: [],
            evergreen_content: []

  use Screens.Config.Struct,
    children: [
      train_crowding: TrainCrowding,
      local_evergreen_sets: {:list, LocalEvergreenSet},
      evergreen_content: {:list, EvergreenContentItem}
    ]
end
