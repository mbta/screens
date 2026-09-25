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
  @spec capture_latest(DateTime.t()) :: {:ok, backup_result()} | {:error, term()}
  def capture_latest(now \\ DateTime.utc_now()) do
    configs = ScreenConfigs.all()

    if any_updated_since_last_backup?(configs) do
      Logster.info(["screen_configs_backup_latest", status: "started"])

      now
      |> DateTime.truncate(:second)
      |> write_backup(configs, &@store.put_latest/1)
    else
      Logster.info(["screen_configs_backup_latest", status: "skipped"])
      {:ok, :skipped}
    end
  end

  @doc "Writes a dated snapshot of the current screen configs."
  @spec capture_daily(DateTime.t()) :: {:ok, backup_result()} | {:error, term()}
  def capture_daily(now \\ DateTime.utc_now()) do
    configs = ScreenConfigs.all()
    now = DateTime.truncate(now, :second)

    Logster.info(["screen_configs_backup_snapshot", status: "started"])
    write_backup(now, configs, &@store.put_daily(&1, DateTime.to_date(now)))
  end

  # Skips writing a new backup if nothing has changed since the last one was exported, to avoid
  # needless S3 writes. Any error reading the existing backup is treated as if it's out of date.
  @spec any_updated_since_last_backup?([ScreenConfig.t()]) :: boolean()
  defp any_updated_since_last_backup?(configs) do
    with {:ok, backup_json} <-
           @store.fetch_latest(environment_name()),
         {:ok, %{"meta" => %{"exported_at" => exported_at}}} <- Jason.decode(backup_json),
         {:ok, exported_at, _offset} <- DateTime.from_iso8601(exported_at) do
      Enum.any?(configs, fn %ScreenConfig{updated_at: updated_at} ->
        DateTime.compare(updated_at, exported_at) == :gt
      end)
    else
      _ -> true
    end
  end

  @spec write_backup(DateTime.t(), [ScreenConfig.t()], (String.t() -> :ok | :error)) ::
          {:ok, backup_result()} | {:error, term()}
  defp write_backup(now, configs, put_backup_fn) do
    payload = %{
      meta: %{
        environment: environment_name(),
        exported_at: DateTime.to_iso8601(now)
      },
      screens:
        Map.new(configs, fn %ScreenConfig{id: id, config: config} ->
          {id, Screen.to_json(config)}
        end)
    }

    with {:ok, json} <- Jason.encode(payload, pretty: true),
         :ok <- put_backup_fn.(json) do
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

  @doc "Dates for which the current environment has a backup."
  @spec dates() :: {:ok, [String.t()]} | :error
  def dates do
    case @store.list_daily(environment_name()) do
      {:ok, dates} -> {:ok, Enum.sort(dates, :desc)}
      :error -> :error
    end
  end

  @doc "Replaces persisted screen configs with the current environment's backup from a date."
  @spec restore_daily(String.t()) :: {:ok, map()} | {:error, restore_error() | :invalid_date}
  def restore_daily(date) do
    with {:ok, backup_screens} <- configs_from_date(date),
         comparison = compare_screens(backup_screens),
         updates =
           Enum.map(comparison.backup, fn {id, config} -> %{id: id, config: config} end),
         deletes = Map.keys(comparison.current) -- Map.keys(comparison.backup),
         :ok <- commit_daily_changes(updates, deletes) do
      {:ok, %{upserted: length(updates), deleted: length(deletes)}}
    end
  end

  @doc "Returns current and dated backup screen configs for comparison."
  @spec compare_daily(String.t()) ::
          {:ok, %{current: map(), backup: map(), differing_ids: [String.t()]}}
          | {:error, restore_error() | :invalid_date}
  def compare_daily(date) do
    with {:ok, backup_configs} <- configs_from_date(date) do
      {:ok, compare_screens(backup_configs)}
    end
  end

  @spec compare_screens(map()) :: %{current: map(), backup: map(), differing_ids: [String.t()]}
  defp compare_screens(backup_configs) do
    current_configs =
      ScreenConfigs.all()
      |> Map.new(fn %ScreenConfig{id: id, config: config} ->
        {id, Screen.to_json(config)}
      end)
      |> normalize_json()

    differing_ids =
      current_configs
      |> Map.keys()
      |> Kernel.++(Map.keys(backup_configs))
      |> Enum.uniq()
      |> Enum.reject(&(Map.get(current_configs, &1) == Map.get(backup_configs, &1)))
      |> Enum.sort()

    %{
      current: Map.take(current_configs, differing_ids),
      backup: Map.take(backup_configs, differing_ids),
      differing_ids: differing_ids
    }
  end

  defp normalize_json(map), do: map |> Jason.encode!() |> Jason.decode!()

  defp commit_daily_changes([], []), do: :ok
  defp commit_daily_changes(updates, deletes), do: ScreenConfigs.commit_updates(updates, deletes)

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
    with {:ok, json} <- @store.fetch_latest(environment),
         {:ok, %{upserted: upserted, deleted: deleted}} <- replace_configs(json),
         {:ok, %{copied: copied}} <- sync_assets(environment) do
      {:ok, %{upserted: upserted, deleted: deleted, assets_copied: copied}}
    else
      :error -> {:error, :backup_fetch_failed}
      {:error, error} -> {:error, error}
    end
  end

  defp replace_configs(json) do
    with {:ok, %{"screens" => screens}} when is_map(screens) <- Jason.decode(json) do
      ScreenConfigs.replace_all(screens)
    else
      {:ok, _decoded} -> {:error, :backup_invalid}
      {:error, %Jason.DecodeError{} = error} -> {:error, {:backup_decode_failed, error}}
    end
  end

  @spec configs_from_date(String.t()) ::
          {:ok, map()}
          | {:error,
             :invalid_date
             | :backup_fetch_failed
             | :backup_invalid
             | {:backup_decode_failed, Jason.DecodeError.t()}}
  defp configs_from_date(date) do
    with {:ok, parsed_date} <- Date.from_iso8601(date),
         {:ok, json} <- @store.fetch_daily(environment_name(), parsed_date),
         {:ok, %{"screens" => screens}} when is_map(screens) <- Jason.decode(json) do
      {:ok, screens}
    else
      {:error, :invalid_format} -> {:error, :invalid_date}
      :error -> {:error, :backup_fetch_failed}
      {:ok, _decoded} -> {:error, :backup_invalid}
      {:error, %Jason.DecodeError{} = error} -> {:error, {:backup_decode_failed, error}}
    end
  end

  defp sync_assets(environment), do: Assets.sync(environment)

  defp environment_name, do: Application.get_env(:screens, :environment_name, "screens-local")

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
