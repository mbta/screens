defmodule Screens.OlCrowding.Agent do
  @moduledoc false
  use Agent

  def start_link(initial_value) do
    Agent.start_link(fn -> initial_value end, name: __MODULE__)
  end

  def get(station_id, direction_id) do
    Agent.get(__MODULE__, &Map.get(&1, "#{station_id}.#{direction_id}"))
  end

  def delete(station_id, direction_id) do
    Agent.update(__MODULE__, &Map.delete(&1, "#{station_id}.#{direction_id}"))
  end

  def put(station_id, direction_id, dwell) do
    Agent.update(__MODULE__, &Map.put(&1, "#{station_id}.#{direction_id}", dwell))
  end
end
