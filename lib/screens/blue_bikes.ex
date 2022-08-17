defmodule Screens.BlueBikes do
  @moduledoc """
  Provides real-time data about BlueBikes stations.
  """
  alias Screens.BlueBikes.State
  alias Screens.BlueBikes.StationStatus

  @type t :: %__MODULE__{
          stations_by_id: %{station_id => StationStatus.t()}
        }

  @type station_id :: String.t()

  @enforce_keys [:stations_by_id]
  defstruct @enforce_keys

  @doc "Gets stations corresponding to the given list of station IDs."
  @spec get_station_statuses(list(station_id)) :: %{station_id => StationStatus.t()}
  defdelegate get_station_statuses(station_ids), to: State
end
