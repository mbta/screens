defmodule Screens.Config.Backup.Store.Local do
  @moduledoc """
  Functions to work with a local copy of the screen configs backup.
  """

  @behaviour Screens.Config.Backup.Store

  @impl true
  def fetch_backup(_environment_name) do
    case File.read(backup_path()) do
      {:ok, contents} -> {:ok, contents}
      {:error, _} -> :error
    end
  end

  @impl true
  def put_backup(file_contents) do
    path = backup_path()

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
end
