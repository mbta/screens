defmodule Screens.Config.State.S3Fetch do
  @moduledoc false

  require Logger
  alias Screens.Config

  @behaviour Config.State.Fetch

  @impl true
  def fetch_config do
    with {:ok, body} <- get_from_s3(),
         {:ok, parsed} <- Jason.decode(body) do
      {:ok, Config.from_json(parsed)}
    else
      _ -> :error
    end
  end

  @impl true
  def get_from_s3 do
    bucket = Application.get_env(:screens, :config_s3_bucket)
    path = config_path_for_environment()
    get_operation = ExAws.S3.get_object(bucket, path)

    case ExAws.request(get_operation) do
      {:ok, %{body: body, status_code: 200}} ->
        {:ok, body}

      {:error, err} ->
        _ = Logger.info("s3_config_fetch_error #{inspect(err)}")
        :error
    end
  end

  @impl true
  def put_to_s3(contents) do
    bucket = Application.get_env(:screens, :config_s3_bucket)
    path = config_path_for_environment()
    put_operation = ExAws.S3.put_object(bucket, path, contents)

    case ExAws.request(put_operation) do
      {:ok, %{status_code: 200}} -> :ok
      _ -> :error
    end
  end

  defp config_path_for_environment do
    "screens/#{Application.get_env(:screens, :environment_name)}.json"
  end
end
