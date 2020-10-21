defmodule Screens.SignsUiConfig.State.LocalFetch do
  @moduledoc false

  alias Screens.SignsUiConfig.State
  @behaviour State.Fetch

  @local_config_path Path.join(:code.priv_dir(:screens), "signs_ui_config.json")

  @spec fetch_config() :: {:ok, State.config()} | :error
  def fetch_config do
    with {:ok, file_contents} <- File.read(@local_config_path),
         {:ok, decoded} <- Jason.decode(file_contents) do
      {:ok, State.Parse.parse_config(decoded)}
    else
      _ -> :error
    end
  end
end
