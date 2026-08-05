defmodule Screens.ScreenConfigs do
  @moduledoc """
  Context for managing screen configuration records persisted to Postgres.
  """

  import Ecto.Query

  alias Screens.Config.Fetch, as: ConfigFetch
  alias Screens.Config.ScreenConfig
  alias Screens.Repo

  @spec import_from_file() :: {:ok, %{upserted: integer(), deleted: integer()}} | {:error, any()}
  def import_from_file do
    # This should be a part of post_config_migration_cleanup
    with {:ok, config, _version} <- ConfigFetch.fetch_config(),
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

  def list do
    Repo.all(ScreenConfig)
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
end
