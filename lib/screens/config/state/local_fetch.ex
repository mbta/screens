defmodule Screens.Config.State.LocalFetch do
  alias Screens.Config

  @local_config_file "local_new.json"

  @spec fetch_config :: {:ok, Config.t()} | :error
  def fetch_config do
    with {:ok, file_contents} <-
           File.read(Path.join(:code.priv_dir(:screens), @local_config_file)),
         {:ok, parsed} <- Jason.decode(file_contents) do
      {:ok, Config.from_json(parsed)}
    else
      _ -> :error
    end
  end
end
