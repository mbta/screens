defmodule Screens.Override.State do
  @moduledoc false

  @initial_fetch_wait_ms 500
  @refresh_ms 15 * 1000
  @default_config %{
    globally_disabled: false,
    disabled_screen_ids: MapSet.new(),
    bus_service: 1,
    green_line_service: 1
  }

  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def lookup(pid \\ __MODULE__, screen_id) do
    GenServer.call(pid, {:lookup, screen_id})
  end

  def bus_service(pid \\ __MODULE__) do
    GenServer.call(pid, :bus_service)
  end

  def green_line_service(pid \\ __MODULE__) do
    GenServer.call(pid, :green_line_service)
  end

  def schedule_refresh(pid, ms \\ @refresh_ms) do
    Process.send_after(pid, :refresh, ms)
    :ok
  end

  ###

  @impl true
  def init(:ok) do
    schedule_refresh(self(), @initial_fetch_wait_ms)
    {:ok, @default_config}
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

  def handle_call(:bus_service, _from, %{bus_service: bus_service} = state) do
    {:reply, bus_service, state}
  end

  def handle_call(:green_line_service, _from, %{green_line_service: green_line_service} = state) do
    {:reply, green_line_service, state}
  end

  @impl true
  def handle_info(:refresh, _state) do
    new_state =
      case Screens.Override.Fetch.fetch_config_from_s3() do
        {:ok, config} -> config
        :error -> @default_config
      end

    schedule_refresh(self())
    {:noreply, new_state}
  end
end
