defmodule Screens.Override.State do
  @moduledoc false

  @initial_fetch_wait_ms 500
  @refresh_ms 5 * 1000

  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def lookup(pid \\ __MODULE__, screen_id) do
    GenServer.call(pid, {:lookup, screen_id})
  end

  def schedule_refresh(pid, ms \\ @refresh_ms) do
    Process.send_after(pid, :refresh, ms)
    :ok
  end

  ###

  @impl true
  def init(:ok) do
    schedule_refresh(self(), @initial_fetch_wait_ms)
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

  @impl true
  def handle_info(:refresh, _state) do
    new_state = Screens.Override.Fetch.fetch_config_from_s3()
    schedule_refresh(self())
    {:noreply, new_state}
  end
end
