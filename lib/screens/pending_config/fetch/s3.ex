defmodule Screens.PendingConfig.Fetch.S3 do
  @moduledoc """
  Functions to work with an S3-hosted copy of the pending screens config.
  """

  require Logger

  @behaviour Screens.PendingConfig.Fetch

  @impl true
  def fetch_config do
    bucket = Application.get_env(:screens, :config_s3_bucket)
    path = config_path_for_environment()

    # Unlike the main screens config, we don't cache the pending screens config.
    # We fetch it anew every time.
    # We don't expect it to be very large, or be requested frequently.
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
  def put_config(file_contents) do
    bucket = Application.get_env(:screens, :config_s3_bucket)
    path = config_path_for_environment()
    put_operation = ExAws.S3.put_object(bucket, path, file_contents)

    case ExAws.request(put_operation) do
      {:ok, %{status_code: 200}} -> :ok
      _ -> :error
    end
  end

  defp config_path_for_environment do
    "screens/pending-#{Application.get_env(:screens, :environment_name)}.json"
  end
end
