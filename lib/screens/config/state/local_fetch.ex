defmodule Screens.Config.State.LocalFetch do
  @moduledoc false

  alias Screens.Config
  @behaviour Screens.ConfigCache.State.Fetch
  @behaviour Config.State.Fetch

  @impl true
  def fetch_config(current_version) do
    with {:ok, file_contents, new_version} <- get_config(current_version),
         {:ok, parsed} <- Jason.decode(file_contents) do
      {:ok, Config.from_json(parsed), new_version}
    else
      _ -> :error
    end
  end

  @impl true
  def get_config(current_version \\ nil) do
    case File.read(local_config_path()) do
      {:ok, contents} -> {:ok, contents, current_version}
      _ -> :error
    end
  end

  @impl true
  def put_config(contents) do
    case File.write(local_config_path(), contents) do
      :ok -> :ok
      {:error, _} -> :error
    end
  end

  defp local_config_path do
    case Application.get_env(:screens, :local_config_file_spec) do
      {:priv, file_name} -> Path.join(:code.priv_dir(:screens), file_name)
      {:test, file_name} -> Path.join(~w[#{File.cwd!()} test fixtures #{file_name}])
    end
  end
end
