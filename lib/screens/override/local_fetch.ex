defmodule Screens.Override.LocalFetch do
  @moduledoc false

  def fetch_config do
    with {:ok, file_contents} <- File.read(Path.join(:code.priv_dir(:screens), "local.json")),
         {:ok, parsed} <- Jason.decode(file_contents, keys: :atoms!) do
      {:ok, Screens.Override.from_json(parsed)}
    else
      _ -> :error
    end
  end
end
