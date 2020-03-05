defmodule Screens.Override.State do
  @moduledoc false

  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def lookup(pid \\ __MODULE__, screen_id) do
    GenServer.call(pid, {:lookup, screen_id})
  end

  def set_state(pid \\ __MODULE__, new_state) do
    GenServer.call(pid, {:set_state, new_state})
  end

  ###

  @impl true
  def init(:ok) do
    {:ok, %{globally_disabled: false, disabled_screen_ids: MapSet.new()}}
  end

  @impl true
  def handle_call({:lookup, _screen_id}, _from, %{globally_disabled: true} = state) do
    {:reply, true, state}
  end

  def handle_call(
        {:lookup, screen_id},
        _from,
        %{globally_disabled: false, disabled_screen_ids: disabled_screen_ids} = state
      ) do
    {:reply, MapSet.member?(disabled_screen_ids, screen_id), state}
  end

  def handle_call({:set_state, new_state}, _from, _state) do
    {:reply, :ok, new_state}
  end
end
