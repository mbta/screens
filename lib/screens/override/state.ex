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

  def api_version(pid \\ __MODULE__) do
    GenServer.call(pid, :api_version)
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

  def bus_psa_list(pid \\ __MODULE__) do
    GenServer.call(pid, :bus_psa_list)
  end

  def green_line_psa_list(pid \\ __MODULE__) do
    GenServer.call(pid, :green_line_psa_list)
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
  def handle_call(:api_version, _from, %Override{api_version: api_version} = state) do
    {:reply, api_version, state}
  end

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

  def handle_call(:bus_service, _from, state) do
    {:reply, state.bus_service, state}
  end

  def handle_call(:green_line_service, _from, state) do
    {:reply, state.green_line_service, state}
  end

  def handle_call({:headway_mode?, screen_id}, _from, state) do
    {:reply, MapSet.member?(state.headway_mode_screen_ids, screen_id), state}
  end

  def handle_call(:bus_psa_list, _from, state) do
    {:reply, state.bus_psa_list, state}
  end

  def handle_call(:green_line_psa_list, _from, state) do
    {:reply, state.green_line_psa_list, state}
  end

  @impl true
  def handle_info(:refresh, _state) do
    override_fetcher = Application.get_env(:screens, :override_fetcher)

    new_state =
      case override_fetcher.fetch_config() do
        {:ok, config} -> config
        :error -> @default_config
      end

    schedule_refresh(self())
    {:noreply, new_state}
  end

  # Handle leaked :ssl_closed messages from Hackney.
  # Workaround for this issue: https://github.com/benoitc/hackney/issues/464
  def handle_info({:ssl_closed, _}, state) do
    {:noreply, state}
  end
end
