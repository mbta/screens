defmodule Screens.Override.State do
  @moduledoc false

  alias Screens.Override

  @initial_fetch_wait_ms 500
  @refresh_ms 15 * 1000
  @default_config Override.new()

  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def disabled?(pid \\ __MODULE__, screen_id) do
    GenServer.call(pid, {:disabled?, screen_id})
  end

  def bus_service(pid \\ __MODULE__) do
    GenServer.call(pid, :bus_service)
  end

  def green_line_service(pid \\ __MODULE__) do
    GenServer.call(pid, :green_line_service)
  end

  def headway_mode?(pid \\ __MODULE__, screen_id) do
    GenServer.call(pid, {:headway_mode?, screen_id})
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
  def handle_call({:disabled?, _screen_id}, _from, %Override{globally_disabled: true} = state) do
    {:reply, true, state}
  end

  def handle_call(
        {:disabled?, screen_id},
        _from,
        %Override{globally_disabled: false, disabled_screen_ids: disabled_screen_ids} = state
      ) do
    {:reply, MapSet.member?(disabled_screen_ids, screen_id), state}
  end

  def handle_call(:bus_service, _from, %Override{bus_service: bus_service} = state) do
    {:reply, bus_service, state}
  end

  def handle_call(:green_line_service, _from, %Override{green_line_service: green_line_service} = state) do
    {:reply, green_line_service, state}
  end

  def handle_call({:headway_mode?, _screen_id}, _from, %Override{globally_disabled: true} = state) do
    {:reply, false, state}
  end

  def handle_call(
        {:headway_mode?, screen_id},
        _from,
        %Override{globally_disabled: false, headway_mode_screen_ids: headway_mode_screen_ids} = state
      ) do
    {:reply, MapSet.member?(headway_mode_screen_ids, screen_id), state}
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
