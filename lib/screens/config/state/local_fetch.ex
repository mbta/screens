defmodule Screens.Config.State.LocalFetch do
  @moduledoc false

  alias Screens.Config

  @local_config_path Path.join(:code.priv_dir(:screens), "local.json")

  @spec fetch_config :: {:ok, Config.t()} | :error
  def fetch_config(path \\ @local_config_path) do
    with {:ok, file_contents} <- get_from_s3(path),
         {:ok, parsed} <- Jason.decode(file_contents) do
      {:ok, Config.from_json(parsed)}
    else
      _ -> :error
    end
  end

  def get_from_s3(path \\ @local_config_path) do
    File.read(path)
  end

  def put_to_s3(contents, path \\ @local_config_path) do
    case File.write(path, contents) do
      :ok -> :ok
      {:error, _} -> :error
    end
  end
end
