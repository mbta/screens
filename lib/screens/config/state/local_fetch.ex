defmodule Screens.Config.State.LocalFetch do
  @moduledoc false

  alias Screens.Config

  @local_config_path Path.join(:code.priv_dir(:screens), "local.json")

  @spec fetch_config :: {:ok, Config.t()} | :error
  def fetch_config(path \\ @local_config_path) do
    with {:ok, file_contents} <- File.read(path),
         {:ok, parsed} <- Jason.decode(file_contents) do
      {:ok, Config.from_json(parsed)}
    else
      _ -> :error
    end
  end
end
