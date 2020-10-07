defmodule Screens.Config.State do
  @moduledoc false

  require Logger

  alias Screens.Config
  alias Screens.Config.{Devops, Screen}

  @typep t :: {Config.t(), retry_count :: non_neg_integer()} | :error
  @config_fetcher Application.get_env(:screens, :config_fetcher)

  use Screens.ConfigCache.State

  def fetch_config, do: @config_fetcher.fetch_config()

  def refresh_ms, do: 15 * 1000
  # Start logging fetch failures as errors after this many minutes of consecutive failures
  def fetch_failure_error_threshold_minutes, do: 2

  def ok?(pid \\ __MODULE__) do
    GenServer.call(pid, :ok?)
  end

  def refresh_if_loaded_before(pid \\ __MODULE__, screen_id) do
    GenServer.call(pid, {:refresh_if_loaded_before, screen_id})
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

  def config(pid \\ __MODULE__) do
    GenServer.call(pid, :config)
  end

  def mode_disabled?(pid \\ __MODULE__, mode) do
    GenServer.call(pid, {:mode_disabled?, mode})
  end

  ###

  @impl true
  def handle_call(:ok?, _from, :error) do
    {:reply, false, :error}
  end

  def handle_call(:ok?, _from, {_config, _retry_count} = state) do
    {:reply, true, state}
  end

  def handle_call({:refresh_if_loaded_before, screen_id}, _from, {config, _} = state) do
    screen = Map.get(config.screens, screen_id)

    refresh_if_loaded_before =
      case screen do
        %Screen{refresh_if_loaded_before: refresh_if_loaded_before} -> refresh_if_loaded_before
        _ -> nil
      end

    {:reply, refresh_if_loaded_before, state}
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

  def handle_call(:config, _from, {config, _} = state) do
    {:reply, config, state}
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

  def handle_call({:mode_disabled?, mode}, _from, {config, _} = state) do
    %Devops{disabled_modes: disabled_modes} = config.devops

    {:reply, Enum.member?(disabled_modes, mode), state}
  end

  # If we're in an error state, all queries on the state get an :error response
  def handle_call(_, _from, :error) do
    {:reply, :error, :error}
  end
end
