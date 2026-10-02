defmodule Screens.Config.Backup.Store.Local do
  @moduledoc """
  Functions to work with a local copy of the screen configs backup.
  """

  @behaviour Screens.Config.Backup.Store

  @impl true
  def fetch_latest(_environment_name) do
    case File.read(backup_path()) do
      {:ok, contents} -> {:ok, contents}
      {:error, _} -> :error
    end
  end

  @impl true
  def fetch_daily(environment, date) do
    case File.read(Path.join(daily_directory(environment), "#{date}.json")) do
      {:ok, contents} -> {:ok, contents}
      {:error, _} -> :error
    end
  end

  @impl true
  def list_daily(environment) do
    dates =
      daily_directory(environment)
      |> Path.join("*.json")
      |> Path.wildcard()
      |> Enum.map(&(&1 |> Path.basename() |> Path.rootname()))

    {:ok, dates}
  end

  @impl true
  def put_latest(file_contents) do
    path = backup_path()

    write(path, file_contents)
  end

  @impl true
  def put_daily(file_contents, date) do
    environment = Application.get_env(:screens, :environment_name)
    path = Path.join(daily_directory(environment), "#{date}.json")

    write(path, file_contents)
  end

  defp write(path, file_contents) do
    with :ok <- File.mkdir_p(Path.dirname(path)),
         :ok <- File.write(path, file_contents) do
      :ok
    else
      {:error, _} -> :error
    end
  end

  defp backup_path do
    Path.join([
      :code.priv_dir(:screens),
      Application.get_env(:screens, __MODULE__)[:local_backup_path]
    ])
  end

  defp daily_directory(environment) do
    Path.join([Path.dirname(backup_path()), "backups", environment])
  end
end
