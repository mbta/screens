defmodule Screens.SignsUiConfig.State.Fetch do
  @moduledoc false

  require Logger

  @spec fetch_config() :: {:ok, Config.t()} | :error
  def fetch_config do
    with {:ok, body} <- get_from_s3(),
         {:ok, decoded} <- Jason.decode(body) do
      {:ok, Screens.SignsUiConfig.State.Parse.parse_config(decoded)}
    else
      _ -> :error
    end
  end

  def get_from_s3 do
    bucket = Application.get_env(:screens, :signs_ui_s3_bucket)
    path = Application.get_env(:screens, :signs_ui_s3_path)
    get_operation = ExAws.S3.get_object(bucket, path)

    case ExAws.request(get_operation) do
      {:ok, %{body: body, status_code: 200}} ->
        {:ok, body}

      {:error, err} ->
        _ = Logger.info("s3_fetch_error #{inspect(err)}")
        :error
    end
  end
end
