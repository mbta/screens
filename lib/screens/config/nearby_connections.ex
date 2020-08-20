defmodule Screens.Config.NearbyConnections do
  @moduledoc false

  @type t :: list(nearby_connection)
  @typep nearby_connection :: {stop_id, list(route_id)}
  @typep stop_id :: String.t()
  @typep route_id :: String.t()

  def from_json(json) when is_list(json) do
    Enum.map(json, &from_json_helper/1)
  end

  def from_json(:default), do: []

  defp from_json_helper([stop_id, route_id_list]) do
    {stop_id, route_id_list}
  end

  def to_json(nearby_connections) do
    Enum.map(nearby_connections, &to_json_helper/1)
  end

  defp to_json_helper({stop_id, route_id_list}) do
    [stop_id, route_id_list]
  end
end
