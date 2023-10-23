defmodule Screens.TriptychPlayer.State.S3Fetch do
  @moduledoc false

  require Logger

  @behaviour Screens.ConfigCache.State.Fetch
  @behaviour Screens.TriptychPlayer.State.Fetch

  @impl Screens.ConfigCache.State.Fetch
  def fetch_config(current_version) do
    with {:ok, body, new_version} <- get_config(current_version),
         {:ok, decoded} <- Jason.decode(body) do
      {:ok, decoded, new_version}
    else
      :unchanged -> :unchanged
      _ -> :error
    end
  end

  @impl Screens.TriptychPlayer.State.Fetch
  def get_config(current_version \\ nil) do
    bucket = Application.get_env(:screens, :triptych_player_s3_bucket)
    path = config_path_for_environment()

    opts =
      case current_version do
        nil -> []
        _ -> [if_none_match: current_version]
      end

    get_operation = ExAws.S3.get_object(bucket, path, opts)

    case ExAws.request(get_operation) do
      {:ok, %{status_code: 304}} ->
        :unchanged

      {:ok, %{body: body, headers: headers, status_code: 200}} ->
        etag =
          headers
          |> Enum.into(%{})
          |> Map.get("ETag")

        {:ok, body, etag}

      {:error, err} ->
        _ = Logger.info("s3_triptych_player_config_fetch_error #{inspect(err)}")
        :error
    end
  end

  @impl Screens.TriptychPlayer.State.Fetch
  def put_config(contents) do
    bucket = Application.get_env(:screens, :triptych_player_s3_bucket)
    path = config_path_for_environment()
    put_operation = ExAws.S3.put_object(bucket, path, contents)

    case ExAws.request(put_operation) do
      {:ok, %{status_code: 200}} -> :ok
      _ -> :error
    end
  end

  defp config_path_for_environment do
    "screens-" <> env = Application.get_env(:screens, :environment_name, "screens-prod")
    "screens/triptych-player-#{env}.json"
  end
end
