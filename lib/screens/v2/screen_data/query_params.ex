defmodule Screens.V2.ScreenData.QueryParams do
  @moduledoc "Encodes valid query parameters that are currently only used by on bus screens."

  @type t :: %__MODULE__{
          route_id: String.t() | nil,
          stop_id: String.t() | nil,
          trip_id: String.t() | nil
        }

  defstruct route_id: nil, stop_id: nil, trip_id: nil

  # Valid keys for URL parameters to be passed into the screen app.
  # To process a new URL parameter, it needs to be added to this list.
  @valid_param_keys ["route_id", "stop_id", "trip_id"]

  def valid_param_keys, do: @valid_param_keys
end
