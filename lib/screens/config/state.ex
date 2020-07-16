defmodule Screens.Config.State do
  alias Screens.Config

  @opaque t :: {Config.t(), retry_count :: non_neg_integer()} | :error

  @initial_fetch_wait_ms 500
  @refresh_ms 15 * 1000
  @max_retries 8

  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def ok?(pid \\ __MODULE__) do
    GenServer.call(pid, :ok?)
  end

  def api_version(pid \\ __MODULE__) do
    GenServer.call(pid, :api_version)
  end

  def bus_service(pid \\ __MODULE__) do
    GenServer.call(pid, :bus_service)
  end

  def green_line_service(pid \\ __MODULE__) do
    GenServer.call(pid, :green_line_service)
  end

  def disabled?(pid \\ __MODULE__, screen_id) do
    GenServer.call(pid, {:disabled?, screen_id})
  end

  def headway_mode?(pid \\ __MODULE__, screen_id) do
    GenServer.call(pid, {:headway_mode?, screen_id})
  end

  def psa_list(pid \\ __MODULE__, screen_id) do
    GenServer.call(pid, {:psa_list, screen_id})
  end

  def audio_psa(pid \\ __MODULE__, screen_id) do
    GenServer.call(pid, {:audio_psa, screen_id})
  end

  def schedule_refresh(pid, ms \\ @refresh_ms) do
    Process.send_after(pid, :refresh, ms)
    :ok
  end

  ###

  @impl true
  def init(:ok) do
    config_fetcher = Application.get_env(:screens, :config_fetcher)

    init_state =
      case config_fetcher.fetch_config() do
        {:ok, config} -> {config, 0}
        :error -> :error
      end

    schedule_refresh(self(), @initial_fetch_wait_ms)
    {:ok, init_state}
  end

  @impl true
  def handle_call(:ok?, _from, :error) do
    {:reply, false, :error}
  end

  def handle_call(:ok?, _from, {_config, _retry_count} = state) do
    {:reply, true, state}
  end

  def handle_call(:api_version, _from, {config, _} = state) do
    {:reply, {:ok, config.api_version}, state}
  end

  def handle_call(:bus_service, _from, {config, _} = state) do
    {:reply, {:ok, config.bus_service}, state}
  end

  def handle_call(:green_line_service, _from, {config, _} = state) do
    {:reply, {:ok, config.green_line_service}, state}
  end

  def handle_call({:disabled?, screen_id}, _from, {config, _} = state) do
    disabled? = get_in(config.screens, [screen_id, Access.key(:disabled)]) || false
    {:reply, {:ok, disabled?}, state}
  end

  def handle_call({:headway_mode?, screen_id}, _from, {config, _} = state) do
    headway_mode? =
      get_in(config.screens, [screen_id, Access.key(:app_params), Access.key(:headway_mode)]) ||
        false

    {:reply, {:ok, headway_mode?}, state}
  end

  def handle_call({:psa_list, screen_id}, _from, {config, _} = state) do
    psa_list =
      get_in(config.screens, [screen_id, Access.key(:app_params), Access.key(:psa_list)]) ||
        {nil, []}

    {:reply, {:ok, psa_list}, state}
  end

  def handle_call({:audio_psa, screen_id}, _from, {config, _} = state) do
    audio_psa =
      get_in(config.screens, [screen_id, Access.key(:app_params), Access.key(:audio_psa)])

    {:reply, {:ok, audio_psa}, state}
  end

  # If we're in an error state, all queries on the state get an :error response
  def handle_call(_, _from, :error) do
    {:reply, :error, :error}
  end

  @impl true
  def handle_info(:refresh, state) do
    config_fetcher = Application.get_env(:screens, :config_fetcher)

    new_state =
      case config_fetcher.fetch_config() do
        {:ok, config} -> {config, 0}
        :error -> error_state(state)
      end

    schedule_refresh(self())
    {:noreply, new_state}
  end

  # Handle leaked :ssl_closed messages from Hackney.
  # Workaround for this issue: https://github.com/benoitc/hackney/issues/464
  def handle_info({:ssl_closed, _}, state) do
    {:noreply, state}
  end

  @spec error_state(t()) :: t()
  defp error_state(:error) do
    :error
  end

  defp error_state({_config, retry_count}) when retry_count >= @max_retries do
    :error
  end

  defp error_state({config, retry_count}) do
    {config, retry_count + 1}
  end
end
