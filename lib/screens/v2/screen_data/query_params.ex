defmodule Screens.V2.ScreenData.QueryParams do
  @moduledoc "Encodes valid query parameters that are currently only used by on bus screens."

  @type t :: %__MODULE__{
          route_id: String.t() | nil,
          stop_id: String.t() | nil,
          trip_id: String.t() | nil
        }

  defstruct route_id: nil, stop_id: nil, trip_id: nil
end
