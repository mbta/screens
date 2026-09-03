defmodule Screens.Config.Backup.Store.S3 do
  @moduledoc """
  Functions to work with S3-hosted backups of the screen configs.
  """

  @behaviour Screens.Config.Backup.Store

  @impl true
  def fetch_backup(environment) do
    get_operation = ExAws.S3.get_object(bucket(), backup_path(environment))

    case ExAws.request(get_operation) do
      {:ok, %{body: body, status_code: 200}} ->
        {:ok, body}

      err ->
        Logster.warning(["s3_screen_configs_backup_fetch_error", inspect(err)])
        :error
    end
  end

  @impl true
  def put_backup(file_contents) do
    path = backup_path(Application.get_env(:screens, :environment_name))
    put_operation = ExAws.S3.put_object(bucket(), path, file_contents)

    case ExAws.request(put_operation) do
      {:ok, %{status_code: 200}} ->
        :ok

      err ->
        Logster.warning(["s3_screen_configs_backup_put_error", inspect(err)])
        :error
    end
  end

  defp bucket, do: Application.get_env(:screens, :config_s3_bucket)

  defp backup_path(environment), do: "screens/latest/#{environment}.json"
end
