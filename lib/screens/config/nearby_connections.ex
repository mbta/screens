defmodule Screens.Config.NearbyConnections do
  @moduledoc false

  alias Screens.Config.NearbyConnection

  @type t :: list(NearbyConnection.t())

  @spec from_json(list() | :default) :: t()
  def from_json(json) when is_list(json) do
    Enum.map(json, &NearbyConnection.from_json/1)
  end

  def from_json(:default), do: []

  @spec to_json(t()) :: list()
  def to_json(nearby_connections) do
    Enum.map(nearby_connections, &NearbyConnection.to_json/1)
  end
end
