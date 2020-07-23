defmodule Screens.Trips.Trip do
  @moduledoc false

  alias Screens.Stops.Stop

  defstruct id: "",
            direction_id: nil,
            headsign: nil,
            route_id: nil,
            stops: nil

  @type id :: String.t()

  @type t :: %__MODULE__{
          id: id,
          direction_id: 0 | 1 | nil,
          headsign: String.t() | nil,
          route_id: String.t() | nil,
          stops: list(Stop.id())
        }
end
