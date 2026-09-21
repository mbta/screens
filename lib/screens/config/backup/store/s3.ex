defmodule Screens.Config.Backup.Store.S3 do
  @moduledoc """
  Functions to work with S3-hosted backups of the screen configs.
  We keep both the latest snapshot and a daily backup so that we can restore to a specific date if needed.
  """
  alias Screens.Report

  @behaviour Screens.Config.Backup.Store

  @impl true
  def fetch_latest(environment) do
    get_operation = ExAws.S3.get_object(bucket(), latest_path(environment))

    case ExAws.request(get_operation) do
      {:ok, %{body: body, status_code: 200}} ->
        {:ok, body}

      err ->
        Logster.warning(["s3_screen_configs_backup_fetch_error", inspect(err)])
        :error
    end
  end

  @impl true
  def put_latest(file_contents) do
    path = latest_path(Application.get_env(:screens, :environment_name))
    put_object(path, file_contents)
  end

  @impl true
  def put_daily(file_contents, date) do
    environment = Application.get_env(:screens, :environment_name)
    put_object(daily_path(environment, date), file_contents)
  end

  defp put_object(path, file_contents) do
    put_operation = ExAws.S3.put_object(bucket(), path, file_contents)

    case ExAws.request(put_operation) do
      {:ok, %{status_code: 200}} ->
        :ok

      err ->
        Report.error("s3_screen_configs_backup_put_error", error: inspect(err))
        :error
    end
  end

  defp bucket, do: Application.get_env(:screens, :config_s3_bucket)

  defp latest_path(environment), do: "screens/latest/#{environment}.json"
  defp daily_path(environment, date), do: "screens/backups/#{environment}/#{date}.json"
end
