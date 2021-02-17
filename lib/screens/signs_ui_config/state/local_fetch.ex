defmodule Screens.SignsUiConfig.State.LocalFetch do
  @moduledoc false

  alias Screens.SignsUiConfig.State
  @behaviour Screens.ConfigCache.State.Fetch

  @local_config_path Path.join(:code.priv_dir(:screens), "signs_ui_config.json")

  @impl true
  def fetch_config(current_version) do
    with {:ok, file_contents} <- File.read(@local_config_path),
         {:ok, decoded} <- Jason.decode(file_contents) do
      {:ok, State.Parse.parse_config(decoded), current_version}
    else
      _ -> :error
    end
  end
end
