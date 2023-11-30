defmodule Screens.TriptychPlayer.Fetch.Local do
  @moduledoc """
  Functions to work with a local copy of the triptych player config.
  """

  @behaviour Screens.TriptychPlayer.Fetch

  @impl true
  def fetch_config(current_version \\ nil) do
    path = local_config_path()

    with {:ok, last_modified} <- get_last_modified(path) do
      if last_modified == current_version do
        :unchanged
      else
        do_fetch(path, last_modified)
      end
    end
  end

  @impl true
  def put_config(file_contents) do
    case File.write(local_config_path(), file_contents) do
      :ok -> :ok
      {:error, _} -> :error
    end
  end

  defp local_config_path do
    case Application.get_env(:screens, :local_triptych_player_file_spec) do
      {:priv, file_name} -> Path.join(:code.priv_dir(:screens), file_name)
      {:test, file_name} -> Path.join(~w[#{File.cwd!()} test fixtures #{file_name}])
    end
  end

  defp do_fetch(path, last_modified) do
    case File.read(path) do
      {:ok, contents} -> {:ok, contents, last_modified}
      _ -> :error
    end
  end

  defp get_last_modified(path) do
    case File.stat(path) do
      {:ok, %File.Stat{mtime: mtime}} -> {:ok, mtime}
      {:error, _} -> :error
    end
  end
end
