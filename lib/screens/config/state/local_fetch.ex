defmodule Screens.Config.State.LocalFetch do
  @moduledoc false

  alias Screens.Config
  @behaviour Screens.ConfigCache.State.Fetch
  @behaviour Config.State.Fetch

  @local_config_path Path.join(:code.priv_dir(:screens), "local.json")

  @impl true
  def fetch_config(current_version) do
    with {:ok, file_contents, new_version} <- get_from_s3(current_version),
         {:ok, parsed} <- Jason.decode(file_contents) do
      {:ok, Config.from_json(parsed), new_version}
    else
      _ -> :error
    end
  end

  @impl true
  def get_from_s3(current_version \\ nil) do
    case File.read(@local_config_path) do
      {:ok, contents} -> {:ok, contents, current_version}
      _ -> :error
    end
  end

  @impl true
  def put_to_s3(contents) do
    case File.write(@local_config_path, contents) do
      :ok -> :ok
      {:error, _} -> :error
    end
  end
end
