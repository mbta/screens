defmodule Screens.SignsUiConfig.State.LocalFetch do
  @moduledoc false

  @local_config_path Path.join(:code.priv_dir(:screens), "signs_ui_config.json")

  def fetch_config(path \\ @local_config_path) do
    with {:ok, file_contents} <- get_from_s3(path),
         {:ok, decoded} <- Jason.decode(file_contents) do
      {:ok, Screens.SignsUiConfig.State.Parse.parse_config(decoded)}
    else
      _ -> :error
    end
  end

  def get_from_s3(path \\ @local_config_path) do
    File.read(path)
  end
end
