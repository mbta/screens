defmodule Screens.Config.Backup do
  @moduledoc """
  Exports all screen configs to JSON, so that any environment's configs can be used as a source
  when syncing another environment.
  """

  import Screens.Inject

  alias Screens.Config.Backup.Assets
  alias Screens.Config.ScreenConfig
  alias Screens.ScreenConfigs
  alias ScreensConfig.Screen

  @store injected(Screens.Config.Backup.Store)

  @type backup_result :: %{count: non_neg_integer()} | :skipped
  @type restore_result :: %{
          upserted: non_neg_integer(),
          deleted: non_neg_integer(),
          assets_copied: non_neg_integer()
        }
  @type restore_error ::
          :backup_fetch_failed
          | :backup_invalid
          | :environment_not_allowed
          | {:backup_decode_failed, Jason.DecodeError.t()}
          | term()

  @deployed_environments ~w[dev dev-green dev-blue prod]

  @doc "Writes a backup of the current screen configs."
  @spec run(DateTime.t()) :: {:ok, backup_result()} | {:error, term()}
  def run(now \\ DateTime.utc_now()) do
    configs = ScreenConfigs.all()

    if any_updated_since_last_backup?(configs) do
      Logster.info(["screen_configs_backup_latest", status: "started"])

      now
      |> DateTime.truncate(:second)
      |> write_backup(configs)
    else
      Logster.info(["screen_configs_backup_latest", status: "skipped"])
      {:ok, :skipped}
    end
  end

  # Skips writing a new backup if nothing has changed since the last one was exported, to avoid
  # needless S3 writes. Any error reading the existing backup is treated as if it's out of date.
  @spec any_updated_since_last_backup?([ScreenConfig.t()]) :: boolean()
  defp any_updated_since_last_backup?(configs) do
    with {:ok, backup_json} <-
           @store.fetch_backup(Application.get_env(:screens, :environment_name)),
         {:ok, %{"meta" => %{"exported_at" => exported_at}}} <- Jason.decode(backup_json),
         {:ok, exported_at, _offset} <- DateTime.from_iso8601(exported_at) do
      Enum.any?(configs, fn %ScreenConfig{updated_at: updated_at} ->
        DateTime.compare(updated_at, exported_at) == :gt
      end)
    else
      _ -> true
    end
  end

  @spec write_backup(DateTime.t(), [ScreenConfig.t()]) ::
          {:ok, backup_result()} | {:error, term()}
  defp write_backup(now, configs) do
    payload = %{
      meta: %{
        environment: Application.get_env(:screens, :environment_name),
        exported_at: DateTime.to_iso8601(now)
      },
      screens:
        Map.new(configs, fn %ScreenConfig{id: id, config: config} ->
          {id, Screen.to_json(config)}
        end)
    }

    with {:ok, json} <- Jason.encode(payload, pretty: true),
         :ok <- @store.put_backup(json) do
      {:ok, %{count: length(configs)}}
    else
      :error -> {:error, :backup_write_failed}
      {:error, error} -> {:error, error}
    end
  end

  @doc """
  Environments whose backups can be used as a restore source in the current environment.
  Restoring is not allowed in prod, and `local` is only available when running locally.
  Do not allow restoring from the current environment, except locally for testing.
  """
  @spec environments() :: [String.t()]
  def environments do
    case readable_current_environment() do
      "prod" -> []
      "local" -> @deployed_environments
      current_env -> List.delete(@deployed_environments, current_env)
    end
  end

  @doc """
  Replaces the persisted screen configs and the environment's assets with the contents of the
  given environment's backup.
  """
  @spec restore(String.t()) :: {:ok, restore_result()} | {:error, restore_error()}
  def restore(environment) do
    if environment in environments() do
      do_restore(full_environment_name(environment))
    else
      {:error, :environment_not_allowed}
    end
  end

  defp do_restore(environment) do
    with {:ok, json} <- @store.fetch_backup(environment),
         {:ok, %{"screens" => screens}} when is_map(screens) <- Jason.decode(json),
         {:ok, %{upserted: upserted, deleted: deleted}} <- ScreenConfigs.replace_all(screens),
         {:ok, %{copied: copied}} <- sync_assets(environment) do
      {:ok, %{upserted: upserted, deleted: deleted, assets_copied: copied}}
    else
      :error -> {:error, :backup_fetch_failed}
      {:ok, _decoded} -> {:error, :backup_invalid}
      {:error, %Jason.DecodeError{} = error} -> {:error, {:backup_decode_failed, error}}
      {:error, error} -> {:error, error}
    end
  end

  defp sync_assets(environment), do: Assets.sync(environment)

  # Deployed environments are named `screens-<environment>`.
  defp readable_current_environment do
    case Application.get_env(:screens, :environment_name) do
      "screens-" <> environment -> environment
      nil -> "local"
      other -> other
    end
  end

  defp full_environment_name(environment), do: "screens-" <> environment
end
