defmodule Screens.ScreenConfigs do
  @moduledoc """
  Context for managing screen configuration records persisted to Postgres.
  """

  import Ecto.Query
  import Screens.Inject

  alias Screens.Config.ScreenConfig
  alias Screens.Repo

  @config_fetcher injected(Screens.Config.Fetch)

  @spec import_from_file() :: {:ok, %{upserted: integer(), deleted: integer()}} | {:error, any()}
  def import_from_file do
    # This should be a part of post_config_migration_cleanup
    with {:ok, config, _version} <- @config_fetcher.fetch_config(),
         config = Jason.decode!(config),
         screens when is_map(screens) <- Map.get(config, "screens", %{}) do
      screen_ids = Map.keys(screens)

      Enum.each(screens, fn {id, config} ->
        upsert_screen_config(%{id: id, config: config})
      end)

      {deleted, _} =
        Repo.delete_all(from s in ScreenConfig, where: s.id not in ^screen_ids)

      {:ok, %{upserted: Enum.count(screen_ids), deleted: deleted}}
    end
  end

  @spec list_all() :: String.t() | :error
  def list_all do
    # Returns all Configs as a JSON to be used by Screens Admin
    if config_migration_enabled?() do
      screens =
        ScreenConfig
        |> Repo.all()
        |> Map.new(fn %ScreenConfig{id: id, config: config} -> {id, config} end)

      Jason.encode!(%{screens: screens})
    else
      with {:ok, config, _version} <- @config_fetcher.fetch_config() do
        config
      end
    end
  end

  @spec list_screen_configs() :: [ScreenConfig.t()]
  def list_screen_configs do
    # Returns all configs as a list of ScreenConfig structs to be used by Screens Admin
    # The API controller handles the JSON encoding and formatting for the response.
    # As part of post_config_migration_cleanup, this and above function can be cleaned up
    if config_migration_enabled?() do
      Repo.all(ScreenConfig)
    else
      with {:ok, config_json, _version} <- @config_fetcher.fetch_config(),
           {:ok, decoded_config} <- Jason.decode(config_json),
           screens when is_map(screens) <- Map.get(decoded_config, "screens", %{}) do
        Enum.map(screens, fn {id, config} ->
          %ScreenConfig{id: id, config: config}
        end)
      else
        _ -> []
      end
    end
  end

  @doc """
  Creates a screen configuration.
  Upserts so an existing config with the same ID will be overwritten.
  """
  @spec upsert_screen_config(params :: map()) ::
          {:ok, ScreenConfig.t()} | {:error, Ecto.Changeset.t()}
  def upsert_screen_config(params) do
    %ScreenConfig{}
    |> ScreenConfig.changeset(params)
    |> Repo.insert(
      on_conflict: {:replace, [:config, :updated_at]},
      conflict_target: :id
    )
  end

  @spec upsert_list([%{:id => String.t(), :config => map()}]) :: :ok | {:error, any()}
  defp upsert_list(updates) do
    Enum.reduce_while(updates, :ok, fn update, _acc ->
      case upsert_screen_config(update) do
        {:ok, _} -> {:cont, :ok}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  @doc """
  Updates and deletes multiple screen configs.
  Accepts a list of maps with :id and :config keys for updates, and a list of screen IDs for deletions.
  """
  @spec commit_updates([%{:id => String.t(), :config => map()}], [String.t()]) ::
          :ok | {:error, any()}
  def commit_updates(updates, deletes \\ []) do
    if config_migration_enabled?() do
      update_to_postgres(updates, deletes)
    else
      # This branch will be removed as part of post_config_migration_cleanup.
      # When the feature flag is disabled, continue to update the JSON config.
      update_to_legacy_json(updates, deletes)
    end
  end

  @spec update_to_postgres([%{:id => String.t(), :config => map()}], [String.t()]) ::
          :ok | {:error, any()}
  defp update_to_postgres(updates, deletes) do
    with :ok <- upsert_list(updates) do
      perform_deletes(deletes)
    end
  end

  @spec perform_deletes([String.t()]) :: :ok | {:error, any()}
  defp perform_deletes(deletes) do
    Enum.reduce_while(deletes, :ok, fn id, _acc ->
      Repo.delete_all(from s in ScreenConfig, where: s.id == ^id)
      {:cont, :ok}
    end)
  end

  defp update_to_legacy_json(updates, deletes) do
    # This will be a part of post_config_migration_cleanup
    # Merges updates into the existing config and removes deleted screens, then writes back to the legacy source.
    # We need to fetch the existing config before writing updates to prevent overwriting any existing configs.
    with {:ok, config_json, _version} <- @config_fetcher.fetch_config(),
         {:ok, decoded_config} <- Jason.decode(config_json),
         screens when is_map(screens) <- Map.get(decoded_config, "screens", %{}) do
      updated_screens =
        Enum.reduce(updates, screens, fn update, acc ->
          id = extract_id(update)
          config = extract_config(update)

          existing_config = Map.get(acc, id, %{})
          merged_config = Map.merge(existing_config, config)
          Map.put(acc, id, merged_config)
        end)

      final_screens = Map.drop(updated_screens, deletes)
      updated_config = Map.put(decoded_config, "screens", final_screens)

      case Jason.encode(updated_config) do
        {:ok, encoded_config} -> @config_fetcher.put_config(encoded_config)
        {:error, reason} -> {:error, reason}
      end
    else
      _ -> :error
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
