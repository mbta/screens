defmodule Screens.Config.State do
  @moduledoc false

  alias Screens.Config
  alias Screens.ConfigCache.State.Fetch
  alias ScreensConfig.{Devops, Screen}

  @config_fetcher Application.compile_env(:screens, :config_fetcher)
  @last_deploy_fetcher Application.compile_env(:screens, :last_deploy_fetcher)

  @type t ::
          %__MODULE__{
            config: Config.t(),
            retry_count: non_neg_integer(),
            version_id: Fetch.version_id(),
            last_deploy_timestamp: DateTime.t() | nil
          }
          | :error

  @enforce_keys [:config]
  defstruct config: nil,
            retry_count: 0,
            version_id: nil,
            last_deploy_timestamp: nil

  use Screens.ConfigCache.State,
    config_module: Screens.Config.State,
    fetch_config_fn: &@config_fetcher.fetch_config/1,
    refresh_ms: 15 * 1000,
    fetch_failure_error_threshold_minutes: 2,
    fetch_last_deploy_fn: &@last_deploy_fetcher.get_last_deploy_time/0

  def ok?(pid \\ __MODULE__) do
    GenServer.call(pid, :ok?)
  end

  def refresh_if_loaded_before(pid \\ __MODULE__, screen_id) do
    GenServer.call(pid, {:refresh_if_loaded_before, screen_id})
  end

  def last_deploy_timestamp(pid \\ __MODULE__) do
    GenServer.call(pid, :last_deploy_timestamp)
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

  @doc """
  Returns a list of all screen IDs, or those that satisfy a filter.

  You may optionally supply a filter function, which will be used to filter the results.
  The filter function will be passed a tuple of {screen_id, screen_config} and should return true if that screen ID should be included in the results.
  """
  @spec screen_ids(nil) :: list(Config.screen_id())
  @spec screen_ids(({Config.screen_id(), Screen.t()} -> as_boolean(term()))) ::
          list(Config.screen_id())
  def screen_ids(filter_fn \\ nil, pid \\ __MODULE__)
      when is_nil(filter_fn) or is_function(filter_fn, 1) do
    GenServer.call(pid, {:screen_ids, filter_fn})
  end

  @doc """
  Gets the full map of screen configurations.

  👉 WARNING: This copies a large amount of data from the Screens.Config.State GenServer process to the process
  that calls this function. This may be of concern for server performance.

  Unless you really need to get the entire map, try to use one of the other client functions, or define a new one
  that does a bit more work in the server process to limit the size of data sent back to the client process.
  """
  def screens(pid \\ __MODULE__) do
    GenServer.call(pid, :screens)
  end

  @doc """
  Gets the entire config struct.

  👉 WARNING: This copies a large amount of data from the Screens.Config.State GenServer process to the process
  that calls this function. This may be of concern for server performance.

  Unless you really need to get the entire config, try to use one of the other client functions, or define a new one
  that does a bit more work in the server process to limit the size of data sent back to the client process.
  """
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

  def handle_call(:ok?, _from, state) do
    {:reply, true, state}
  end

  def handle_call(
        {:refresh_if_loaded_before, screen_id},
        _from,
        %__MODULE__{config: config, last_deploy_timestamp: last_deploy_timestamp} = state
      ) do
    screen = Map.get(config.screens, screen_id)

    refresh_if_loaded_before =
      case screen do
        %Screen{refresh_if_loaded_before: refresh_if_loaded_before} -> refresh_if_loaded_before
        _ -> nil
      end

    case {last_deploy_timestamp, refresh_if_loaded_before} do
      {nil, nil} ->
        {:reply, nil, state}

      {nil, refresh_if_loaded_before} ->
        {:reply, refresh_if_loaded_before, state}

      {last_deploy_timestamp, nil} ->
        {:reply, last_deploy_timestamp, state}

      {last_deploy_timestamp, refresh_if_loaded_before} ->
        if DateTime.compare(last_deploy_timestamp, refresh_if_loaded_before) == :gt do
          {:reply, last_deploy_timestamp, state}
        else
          {:reply, refresh_if_loaded_before, state}
        end
    end
  end

  def handle_call(
        :last_deploy_timestamp,
        _from,
        %__MODULE__{last_deploy_timestamp: last_deploy_timestamp} = state
      ) do
    {:reply, last_deploy_timestamp, state}
  end

  def handle_call({:service_level, screen_id}, _from, %__MODULE__{config: config} = state) do
    screen = Map.get(config.screens, screen_id)

    service_level =
      case screen do
        %Screen{app_params: %{service_level: service_level}} -> service_level
        _ -> 1
      end

    {:reply, service_level, state}
  end

  def handle_call({:disabled?, screen_id}, _from, %__MODULE__{config: config} = state) do
    screen = Map.get(config.screens, screen_id)

    disabled? =
      case screen do
        %Screen{disabled: disabled} -> disabled
        nil -> false
      end

    {:reply, disabled?, state}
  end

  def handle_call({:screen, screen_id}, _from, %__MODULE__{config: config} = state) do
    screen = Map.get(config.screens, screen_id)

    {:reply, screen, state}
  end

  def handle_call(:screens, _from, %__MODULE__{config: config} = state) do
    {:reply, config.screens, state}
  end

  def handle_call(:config, _from, %__MODULE__{config: config} = state) do
    {:reply, config, state}
  end

  def handle_call({:app_params, screen_id}, _from, %__MODULE__{config: config} = state) do
    screen = Map.get(config.screens, screen_id)

    app_params =
      case screen do
        %Screen{app_params: app_params} -> app_params
        nil -> nil
      end

    {:reply, app_params, state}
  end

  def handle_call({:screen_ids, nil}, _from, %__MODULE__{config: config} = state) do
    {:reply, Map.keys(config.screens), state}
  end

  def handle_call({:screen_ids, filter_fn}, _from, %__MODULE__{config: config} = state) do
    ids =
      config.screens
      |> Enum.filter(filter_fn)
      |> Enum.map(fn {screen_id, _screen_config} -> screen_id end)

    {:reply, ids, state}
  end

  def handle_call({:mode_disabled?, mode}, _from, %__MODULE__{config: config} = state) do
    %Devops{disabled_modes: disabled_modes} = config.devops

    {:reply, Enum.member?(disabled_modes, mode), state}
  end

  # If we're in an error state, all queries on the state get an :error response
  def handle_call(_, _from, :error) do
    {:reply, :error, :error}
  end
end
