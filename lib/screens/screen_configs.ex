defmodule Screens.ScreenConfigs do
  @moduledoc """
  Context for managing screen configuration records persisted to Postgres.
  """

  import Ecto.Query
  import Screens.Inject

  alias Screens.Config.ScreenConfig
  alias Screens.Repo
  alias ScreensConfig.Screen

  @data_cache injected(Screens.V2.ScreenData.Cache)

  @type screen_id :: String.t()
  @type screen_update :: %{(atom() | String.t()) => term()}
  @type commit_error ::
          {:upsert_failed, String.t()}
          | {:delete_failed, String.t()}
          | {:transaction_failed, Nebulex.Error.t()}

  @type replace_result :: %{upserted: non_neg_integer(), deleted: non_neg_integer()}

  @doc """
  Replaces all persisted screen configs with the given map of screen ID to JSON config,
  deleting any configs whose IDs are not present in the map.
  """
  @spec replace_all(%{optional(screen_id()) => map()}) ::
          {:ok, replace_result()} | {:error, commit_error()}
  def replace_all(screens) when is_map(screens) do
    screen_ids = Map.keys(screens)
    updates = Enum.map(screens, fn {id, config} -> %{id: id, config: config} end)

    stale_ids =
      Repo.all(from s in ScreenConfig, where: s.id not in ^screen_ids, select: s.id)

    with :ok <- upsert_all(updates), :ok <- delete_all(stale_ids) do
      {:ok, %{upserted: Enum.count(screen_ids), deleted: Enum.count(stale_ids)}}
    end
  end

  @doc "Fetches a single screen's configuration by its ID."
  @spec fetch(screen_id()) :: {:ok, Screen.t() | nil}
  def fetch(id) do
    case Repo.get(ScreenConfig, id) do
      %ScreenConfig{config: %Screen{} = screen} -> {:ok, screen}
      nil -> {:ok, nil}
    end
  end

  @doc "Returns all configs as a list of ScreenConfig structs."
  @spec all() :: [ScreenConfig.t()]
  def all do
    Repo.all(ScreenConfig)
  end

  @doc "Returns all Configs as JSON with the ID as a key and the configuration as the value."
  @spec list_all() :: String.t()
  def list_all do
    screens =
      ScreenConfig
      |> Repo.all()
      |> Map.new(fn %ScreenConfig{id: id, config: config} ->
        {id, Screen.to_json(config)}
      end)

    Jason.encode!(%{screens: screens})
  end

  @doc "Returns screen IDs for screens matching the given app ID."
  @spec screen_ids_for_app(Screen.app_id()) :: [screen_id()]
  def screen_ids_for_app(target_app_id) do
    ScreenConfig
    |> Repo.all()
    |> Enum.filter(&match?(%ScreenConfig{config: %Screen{app_id: ^target_app_id}}, &1))
    |> Enum.map(& &1.id)
  end

  @doc "Returns screen IDs that are eligible for Screenplay self-refresh."
  @spec self_refresh_screen_ids() :: [screen_id()]
  def self_refresh_screen_ids do
    ScreenConfig
    |> Repo.all()
    |> Enum.filter(
      &match?(
        %ScreenConfig{config: %Screen{disabled: false, hidden_from_screenplay: false}},
        &1
      )
    )
    |> Enum.map(& &1.id)
  end

  @doc "Returns Configs filtered by a list of screen IDs as JSON with the ID as a key and the configuration as the value."
  @spec list_by_ids(ids :: [screen_id()]) :: String.t()
  def list_by_ids(ids) when is_list(ids) do
    screens =
      ScreenConfig
      |> where([screen_config], screen_config.id in ^ids)
      |> Repo.all()
      |> Map.new(fn %ScreenConfig{id: id, config: config} ->
        {id, Screen.to_json(config)}
      end)

    Jason.encode!(%{screens: screens})
  end

  @doc """
  Updates and deletes multiple screen configs.
  Accepts a list of maps with :id and :config keys for updates, and a list of screen IDs for deletions.
  """
  @spec commit_updates([screen_update()], [screen_id()]) :: :ok | {:error, commit_error()}
  def commit_updates(updates, deletes \\ []) do
    update_ids =
      Enum.map(updates, fn
        %{id: id} -> id
        %{"id" => id} -> id
      end)

    (update_ids ++ deletes)
    |> Enum.uniq()
    |> @data_cache.invalidate(fn ->
      with :ok <- upsert_all(updates), do: delete_all(deletes)
    end)
    |> case do
      {:ok, result} -> result
      {:error, error} -> {:error, {:transaction_failed, error}}
    end
  end

  @doc "Deletes multiple screen configs based on a list of IDs."
  @spec commit_deletes([screen_id()]) :: :ok | {:error, commit_error()}
  def commit_deletes(deletes) do
    delete_all(deletes)
  end

  @doc "Schedules the requested screens to refresh by setting `refresh_if_loaded_before`."
  @spec schedule_refresh_for_screen_ids([screen_id()], DateTime.t()) ::
          :ok | {:error, commit_error()}
  def schedule_refresh_for_screen_ids(screen_ids, now \\ DateTime.utc_now()) do
    updates =
      ScreenConfig
      |> where([screen_config], screen_config.id in ^screen_ids)
      |> Repo.all()
      |> Enum.map(fn %ScreenConfig{id: id, config: config} ->
        %{id: id, config: Screen.schedule_refresh_at_time(config, now)}
      end)

    commit_updates(updates)
  end

  @spec upsert_all([screen_update()]) :: :ok | {:error, commit_error()}
  defp upsert_all(updates) do
    Enum.reduce_while(updates, :ok, fn update, _acc ->
      case upsert(update) do
        {:ok, _} ->
          {:cont, :ok}

        {:error, %Ecto.Changeset{} = changeset} ->
          {:halt,
           {:error, {:upsert_failed, "ID #{update[:id]} failed: #{inspect(changeset.errors)}"}}}
      end
    end)
  end

  # Creates a screen configuration.
  # Upserts so an existing config with the same ID will be overwritten.
  @spec upsert(params :: map()) :: {:ok, ScreenConfig.t()} | {:error, Ecto.Changeset.t()}
  defp upsert(params) do
    %ScreenConfig{}
    |> ScreenConfig.changeset(params)
    |> Repo.insert(
      on_conflict: {:replace, [:config, :updated_at]},
      conflict_target: :id
    )
  end

  @spec delete_all([screen_id()]) :: :ok | {:error, commit_error()}
  defp delete_all(ids) do
    Enum.reduce_while(ids, :ok, fn id, _acc ->
      case delete(id) do
        :ok -> {:cont, :ok}
        {:error, _} = error -> {:halt, error}
      end
    end)
  end

  @spec delete(screen_id()) :: :ok | {:error, commit_error()}
  defp delete(id) do
    case Repo.delete_all(from s in ScreenConfig, where: s.id == ^id) do
      {count, _} when count > 0 ->
        :ok

      {0, _} ->
        {:error, {:delete_failed, "Config for screen ID #{id} not found"}}

      response ->
        {:error, {:delete_failed, "Unexpected delete operation response: #{inspect(response)}"}}
    end
  end
end
