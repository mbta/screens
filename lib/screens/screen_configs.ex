defmodule Screens.ScreenConfigs do
  @moduledoc """
  Context for managing screen configuration records persisted to Postgres.
  """

  import Ecto.Query
  import Screens.Inject

  alias Screens.Config.ScreenConfig
  alias Screens.Repo
  alias ScreensConfig.Screen

  @cache injected(Screens.Config.Cache)
  @config_fetcher injected(Screens.Config.Fetch)

  @type screen_id :: String.t()
  @type screen_update :: %{required(:id) => screen_id(), required(:config) => map()}
  @type commit_error ::
          {:upsert_failed, String.t()}
          | {:delete_failed, String.t()}
          | {:legacy_fetch_failed, term()}
          | {:legacy_decode_failed, Jason.DecodeError.t()}
          | {:legacy_encode_failed, Jason.EncodeError.t()}
          | :legacy_write_failed
          | :legacy_screens_invalid

  @spec import_from_file() ::
          {:ok, %{upserted: integer(), deleted: integer()}} | {:error, commit_error()}
  def import_from_file do
    # This should be a part of post_config_migration_cleanup
    with {:ok, config, _version} <- @config_fetcher.fetch_config(),
         config = Jason.decode!(config),
         screens when is_map(screens) <- Map.get(config, "screens", %{}) do
      screen_ids = Map.keys(screens)

      Enum.each(screens, fn {id, config} ->
        upsert(%{id: id, config: config})
      end)

      stale_ids =
        Repo.all(from s in ScreenConfig, where: s.id not in ^screen_ids, select: s.id)

      case perform_deletes(stale_ids) do
        :ok ->
          {:ok, %{upserted: Enum.count(screen_ids), deleted: Enum.count(stale_ids)}}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  @spec fetch(screen_id()) :: {:ok, Screen.t() | nil} | {:error, :cache_unavailable}
  def fetch(id) do
    if config_migration_enabled?() do
      case Repo.get(ScreenConfig, id) do
        %ScreenConfig{config: %Screen{} = screen} -> {:ok, screen}
        nil -> {:ok, nil}
      end
    else
      if Screens.Config.Cache.ok?() do
        {:ok, @cache.screen(id)}
      else
        {:error, :cache_unavailable}
      end
    end
  end

  @doc "Returns all configs as a list of ScreenConfig structs."
  @spec all() :: [ScreenConfig.t()]
  def all do
    Repo.all(ScreenConfig)
  end

  @doc "Returns all Configs as JSON with the ID as a key and the configuration as the value."
  @spec list_all() :: String.t() | :error
  def list_all do
    if config_migration_enabled?() do
      screens =
        ScreenConfig
        |> Repo.all()
        |> Map.new(fn %ScreenConfig{id: id, config: config} ->
          {id, Screen.to_json(config)}
        end)

      Jason.encode!(%{screens: screens})
    else
      with {:ok, config, _version} <- @config_fetcher.fetch_config() do
        config
      end
    end
  end

  @doc "Returns screen IDs for screens matching the given app ID."
  @spec screen_ids_for_app(atom()) :: [screen_id()]
  def screen_ids_for_app(target_app_id) do
    if config_migration_enabled?() do
      ScreenConfig
      |> Repo.all()
      |> Enum.filter(&match?(%ScreenConfig{config: %Screen{app_id: ^target_app_id}}, &1))
      |> Enum.map(& &1.id)
    else
      Screens.Config.Cache.screen_ids(&match?({_screen_id, %Screen{app_id: ^target_app_id}}, &1))
    end
  end

  @doc "Returns screen IDs that are eligible for Screenplay self-refresh."
  @spec self_refresh_screen_ids() :: [screen_id()]
  def self_refresh_screen_ids do
    if config_migration_enabled?() do
      ScreenConfig
      |> Repo.all()
      |> Enum.filter(
        &match?(
          %ScreenConfig{config: %Screen{disabled: false, hidden_from_screenplay: false}},
          &1
        )
      )
      |> Enum.map(& &1.id)
    else
      Screens.Config.Cache.screen_ids(fn {_id,
                                          %Screen{
                                            disabled: disabled,
                                            hidden_from_screenplay: hidden
                                          }} ->
        not disabled and not hidden
      end)
    end
  end

  @doc """
  Creates a screen configuration.
  Upserts so an existing config with the same ID will be overwritten.
  """
  @spec upsert(params :: map()) :: {:ok, ScreenConfig.t()} | {:error, Ecto.Changeset.t()}
  def upsert(params) do
    %ScreenConfig{}
    |> ScreenConfig.changeset(params)
    |> Repo.insert(
      on_conflict: {:replace, [:config, :updated_at]},
      conflict_target: :id
    )
  end

  @spec upsert_list([screen_update()]) :: :ok | {:error, commit_error()}
  defp upsert_list(updates) do
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

  @doc """
  Updates and deletes multiple screen configs.
  Accepts a list of maps with :id and :config keys for updates, and a list of screen IDs for deletions.
  """
  @spec commit_updates([screen_update()], [screen_id()]) ::
          :ok | {:error, commit_error()}
  def commit_updates(updates, deletes \\ []) do
    if config_migration_enabled?() do
      upsert_list(updates)
    else
      # This branch will be removed as part of post_config_migration_cleanup.
      # When the feature flag is disabled, continue to update the JSON config.
      update_to_legacy_json(updates, deletes)
    end
  end

  @doc "Deletes multiple screen configs based on a list of IDs."
  @spec commit_deletes([screen_id()]) :: :ok | {:error, commit_error()}
  def commit_deletes(deletes) do
    if config_migration_enabled?() do
      perform_deletes(deletes)
    else
      # This branch will be removed as part of post_config_migration_cleanup.
      # When the feature flag is disabled, continue to update the JSON config.
      update_to_legacy_json([], deletes)
    end
  end

  @spec perform_deletes([screen_id()]) :: :ok | {:error, commit_error()}
  defp perform_deletes(deletes) do
    Enum.reduce_while(deletes, :ok, fn id, _acc ->
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

  # This will be a part of post_config_migration_cleanup
  # Merges updates into the existing config and removes deleted screens, then writes back to the legacy source.
  # We need to fetch the existing config before writing updates to prevent overwriting any existing configs.
  @spec update_to_legacy_json([screen_update()], [screen_id()]) ::
          :ok | {:error, commit_error()}
  defp update_to_legacy_json(updates, deletes) do
    with {:ok, config_json, _version} <- @config_fetcher.fetch_config(),
         {:ok, decoded_config} <- Jason.decode(config_json) do
      screens = Map.get(decoded_config, "screens", %{})

      if is_map(screens) do
        updated_screens =
          Enum.reduce(updates, screens, fn update, acc ->
            id = extract_id(update)

            merged_config =
              acc
              |> Map.get(id, %{})
              |> Map.merge(extract_config(update))

            Map.put(acc, id, merged_config)
          end)

        final_screens = Map.drop(updated_screens, deletes)
        updated_config = Map.put(decoded_config, "screens", final_screens)

        case Jason.encode(updated_config) do
          {:ok, encoded_config} ->
            case @config_fetcher.put_config(encoded_config) do
              :ok -> :ok
              :error -> {:error, :legacy_write_failed}
            end

          {:error, %Jason.EncodeError{} = reason} ->
            {:error, {:legacy_encode_failed, reason}}
        end
      else
        {:error, :legacy_screens_invalid}
      end
    else
      {:error, %Jason.DecodeError{} = reason} -> {:error, {:legacy_decode_failed, reason}}
      reason -> {:error, {:legacy_fetch_failed, reason}}
    end
  end

  @spec config_migration_enabled?() :: boolean()
  def config_migration_enabled? do
    # This will be a part of post_config_migration_cleanup
    Application.get_env(:screens, :config_migration, false)
  end

  # This will be a part of post_config_migration_cleanup
  defp extract_id(%{"id" => id}), do: id
  defp extract_id(%{id: id}), do: id
  defp extract_id(_), do: nil

  # This will be a part of post_config_migration_cleanup
  defp extract_config(%{"config" => config}), do: config
  defp extract_config(%{config: config}), do: config
  defp extract_config(_), do: %{}
end
