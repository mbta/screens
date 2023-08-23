defmodule Screens.TriptychPlayer.State.S3Fetch do
  @moduledoc false

  @behaviour Screens.ConfigCache.State.Fetch

  require Logger

  @impl true
  def fetch_config(current_version) do
    with {:ok, body, new_version} <- get_from_s3(current_version),
         {:ok, decoded} <- Jason.decode(body) do
      {:ok, decoded, new_version}
    else
      :unchanged -> :unchanged
      _ -> :error
    end
  end

  def get_from_s3(current_version \\ nil) do
    bucket = Application.get_env(:screens, :triptych_player_s3_bucket)
    path = path_for_environment()

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

  defp path_for_environment do
    "screens-" <> env = Application.get_env(:screens, :environment_name, "screens-prod")
    "screens/triptych-player-#{env}.json"
  end
end
