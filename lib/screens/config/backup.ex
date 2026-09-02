defmodule Screens.Config.Backup do
  @moduledoc """
  Exports all screen configs to JSON, so that any environment's configs can be used as a source
  when syncing another environment.
  """

  import Screens.Inject

  alias Screens.Config.Backup
  alias Screens.Config.ScreenConfig
  alias Screens.Repo.AdvisoryLock
  alias Screens.ScreenConfigs
  alias ScreensConfig.Screen

  @store injected(Screens.Config.Backup.Store)

  @type result :: %{count: non_neg_integer()}

  @cron_lock_key 1
  @interval Application.compile_env!(:screens, [Backup, :interval_ms])

  @doc """
  Writes a backup of the current screen configs. Returns `:locked` if another instance is already
  running a backup.
  """
  @spec run(DateTime.t()) :: {:ok, result()} | :locked | {:error, term()}
  def run(now \\ DateTime.utc_now()) do
    AdvisoryLock.with_lock(
      @cron_lock_key,
      @interval,
      fn -> export(DateTime.truncate(now, :second)) end
    )
  end

  @spec export(DateTime.t()) :: {:ok, result()} | {:error, term()}
  defp export(now) do
    configs = ScreenConfigs.all()

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
