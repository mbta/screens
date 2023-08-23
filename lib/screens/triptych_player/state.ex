defmodule Screens.TriptychPlayer.State do
  alias Screens.ConfigCache.State.Fetch
  alias Screens.Config

  @fetcher Application.compile_env(:screens, :triptych_player_fetcher)
  @last_deploy_fetcher Application.compile_env(:screens, :last_deploy_fetcher)

  @type t ::
          %__MODULE__{
            config: mapping,
            retry_count: non_neg_integer(),
            version_id: Fetch.version_id(),
            last_deploy_timestamp: DateTime.t() | nil
          }
          | :error

  @type mapping :: %{ofm_player_name => Config.screen_id()}

  @type ofm_player_name :: String.t()

  @enforce_keys [:config]
  defstruct config: nil,
            retry_count: 0,
            version_id: nil,
            last_deploy_timestamp: nil

  use Screens.ConfigCache.State,
    config_module: __MODULE__,
    fetch_config_fn: &@fetcher.fetch_config/1,
    refresh_ms: 15 * 1000,
    fetch_failure_error_threshold_minutes: 0,
    fetch_last_deploy_fn: &@last_deploy_fetcher.get_last_deploy_time/0

  @spec fetch_screen_id_for_player(GenServer.server(), ofm_player_name) ::
          {:ok, Config.screen_id()} | :error
  def fetch_screen_id_for_player(pid \\ __MODULE__, player_name) do
    GenServer.call(pid, {:lookup, player_name})
  end

  @spec fetch_player_names_for_screen_id(GenServer.server(), Config.screen_id()) ::
          {:ok, nonempty_list(ofm_player_name)} | :error
  def fetch_player_names_for_screen_id(pid \\ __MODULE__, screen_id) do
    GenServer.call(pid, {:reverse_lookup, screen_id})
  end

  ###

  @impl true
  def handle_call({:lookup, player_name}, _from, %__MODULE__{config: mapping} = state) do
    {:reply, Map.fetch(mapping, player_name), state}
  end

  def handle_call({:reverse_lookup, screen_id}, _from, %__MODULE__{config: mapping} = state) do
    player_names = for {player_name, ^screen_id} <- mapping, uniq: true, do: player_name

    case player_names do
      [] -> {:reply, :error, state}
      l -> {:reply, {:ok, l}, state}
    end
  end

  def handle_call(_, _from, :error) do
    {:reply, :error, :error}
  end
end
