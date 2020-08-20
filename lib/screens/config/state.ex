defmodule Screens.Config.State do
  @moduledoc false

  require Logger

  alias Screens.Config
  alias Screens.Config.Screen

  @typep t :: {Config.t(), retry_count :: non_neg_integer()} | :error

  @initial_fetch_wait_ms 500
  @refresh_ms 15 * 1000
  # Start logging fetch failures as errors after this many minutes of consecutive failures
  @fetch_failure_error_threshold_minutes 2

  @config_fetcher Application.get_env(:screens, :config_fetcher)

  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def ok?(pid \\ __MODULE__) do
    GenServer.call(pid, :ok?)
  end

  def refresh_after(pid \\ __MODULE__, screen_id) do
    GenServer.call(pid, {:refresh_after, screen_id})
  end

  def service_level(pid \\ __MODULE__, screen_id) do
    GenServer.call(pid, {:service_level, screen_id})
  end

  def disabled?(pid \\ __MODULE__, screen_id) when is_binary(screen_id) do
    GenServer.call(pid, {:disabled?, screen_id})
  end

  def screen(pid \\ __MODULE__, screen_id) when is_binary(screen_id) do
    GenServer.call(pid, {:screen, screen_id})
  end

  def app_params(pid \\ __MODULE__, screen_id) when is_binary(screen_id) do
    GenServer.call(pid, {:app_params, screen_id})
  end

  def screens(pid \\ __MODULE__) do
    GenServer.call(pid, :screens)
  end

  def schedule_refresh(pid, ms \\ @refresh_ms) do
    Process.send_after(pid, :refresh, ms)
    :ok
  end

  ###

  @impl true
  def init(:ok) do
    init_state =
      case @config_fetcher.fetch_config() do
        {:ok, config} -> {config, 0}
        :error -> error_state(:error)
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

  def handle_call({:refresh_after, screen_id}, _from, {config, _} = state) do
    screen = Map.get(config.screens, screen_id)

    refresh_after =
      case screen do
        %Screen{refresh_after: refresh_after} -> refresh_after
        _ -> nil
      end

    {:reply, refresh_after, state}
  end

  def handle_call({:service_level, screen_id}, _from, {config, _} = state) do
    screen = Map.get(config.screens, screen_id)

    service_level =
      case screen do
        %Screen{app_params: %{service_level: service_level}} -> service_level
        _ -> 1
      end

    {:reply, service_level, state}
  end

  def handle_call(:green_line_service, _from, {config, _} = state) do
    {:reply, config.green_line_service, state}
  end

  def handle_call({:disabled?, screen_id}, _from, {config, _} = state) do
    screen = Map.get(config.screens, screen_id)

    disabled? =
      case screen do
        %Screen{disabled: disabled} -> disabled
        nil -> false
      end

    {:reply, disabled?, state}
  end

  def handle_call({:screen, screen_id}, _from, {config, _} = state) do
    screen = Map.get(config.screens, screen_id)

    {:reply, screen, state}
  end

  def handle_call(:screens, _from, {config, _} = state) do
    {:reply, config.screens, state}
  end

  def handle_call({:app_params, screen_id}, _from, {config, _} = state) do
    screen = Map.get(config.screens, screen_id)

    app_params =
      case screen do
        %Screen{app_params: app_params} -> app_params
        nil -> nil
      end

    {:reply, app_params, state}
  end

  # If we're in an error state, all queries on the state get an :error response
  def handle_call(_, _from, :error) do
    {:reply, :error, :error}
  end

  @impl true
  def handle_info(:refresh, state) do
    new_state =
      case @config_fetcher.fetch_config() do
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

  # Logs fetch failures and returns the appropriate error state.
  @spec error_state(current_state :: t()) :: t()
  defp error_state(:error) do
    _ = Logger.error("config_state_init_fetch_error")
    :error
  end

  defp error_state({config, retry_count}) do
    log_message = "config_state_fetch_error retry_count=#{retry_count}"

    _ =
      if log_as_error?(retry_count) do
        Logger.error(log_message)
      else
        Logger.info(log_message)
      end

    {config, retry_count + 1}
  end

  defp log_as_error?(retry_count) do
    threshold_ms = @fetch_failure_error_threshold_minutes * 60 * 1000

    retry_count * @refresh_ms >= threshold_ms
  end
end
