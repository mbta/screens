defmodule Screens.Config.Backup do
  @moduledoc """
  Exports all screen configs to JSON, so that any environment's configs can be used as a source
  when syncing another environment.
  """

  import Screens.Inject

  alias Screens.Config.ScreenConfig
  alias Screens.ScreenConfigs
  alias ScreensConfig.Screen

  @store injected(Screens.Config.Backup.Store)

  @type result :: %{count: non_neg_integer()} | :skipped

  @doc "Writes a backup of the current screen configs."
  @spec run(DateTime.t()) :: {:ok, result()} | {:error, term()}
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

  @spec write_backup(DateTime.t(), [ScreenConfig.t()]) :: {:ok, result()} | {:error, term()}
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
end
