defmodule Screens.Trips.Trip do
  @moduledoc false

  alias Screens.Stops.Stop

  defstruct id: "",
            direction_id: nil,
            headsign: nil,
            route_id: nil,
            stops: nil

  @type id :: String.t()
  @type direction :: 0 | 1

  @type t :: %__MODULE__{
          id: id,
          direction_id: direction(),
          headsign: String.t() | nil,
          route_id: String.t() | nil,
          stops: list(Stop.id())
        }
end
