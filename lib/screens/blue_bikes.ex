defmodule Screens.BlueBikes do
  @moduledoc """
  Provides real-time data about BlueBikes stations.
  """
  alias Screens.BlueBikes.Station
  alias Screens.BlueBikes.State

  @type t :: %__MODULE__{
          stations_by_id: %{station_id => Station.t()}
        }

  @type station_id :: String.t()

  @enforce_keys [:stations_by_id]
  defstruct @enforce_keys

  @doc "Gets stations corresponding to the given list of station IDs."
  @spec get_stations(list(String.t())) :: list(Station.t())
  defdelegate get_stations(station_ids), to: State
end
