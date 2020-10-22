defmodule Screens.Config.State.LocalFetch do
  @moduledoc false

  alias Screens.Config
  @behaviour Config.State.Fetch

  @local_config_path Path.join(:code.priv_dir(:screens), "local.json")

  @impl true
  def fetch_config do
    with {:ok, file_contents} <- get_from_s3(),
         {:ok, parsed} <- Jason.decode(file_contents) do
      {:ok, Config.from_json(parsed)}
    else
      _ -> :error
    end
  end

  @impl true
  def get_from_s3 do
    File.read(@local_config_path)
  end

  @impl true
  def put_to_s3(contents) do
    case File.write(@local_config_path, contents) do
      :ok -> :ok
      {:error, _} -> :error
    end
  end
end
