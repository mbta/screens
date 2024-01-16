defmodule Screens.PendingConfig.Fetch.Local do
  @moduledoc """
  Functions to work with a local copy of the pending screens config.
  """

  @behaviour Screens.PendingConfig.Fetch

  @impl true
  def fetch_config do
    case File.read(local_config_path()) do
      {:ok, contents} -> {:ok, contents}
      _ -> :error
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
    case Application.get_env(:screens, :local_pending_config_file_spec) do
      {:priv, file_name} -> Path.join(:code.priv_dir(:screens), file_name)
      {:test, file_name} -> Path.join(~w[#{File.cwd!()} test fixtures #{file_name}])
    end
  end
end
