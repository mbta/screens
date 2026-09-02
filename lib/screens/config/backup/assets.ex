defmodule Screens.Config.Backup.Assets do
  @moduledoc """
  Copies screen assets (images, videos, etc.) from a source environment into the environment the
  app is running in. When running locally, assets are written to a local directory instead of S3.
  """

  alias ExAws.S3

  @bucket "mbta-screens"
  # Written by the deploy process, so it should never be copied between environments.
  @excluded_keys ~w[LAST_DEPLOY]

  @type result :: %{copied: non_neg_integer()}

  @max_concurrency 20

  @doc """
  Copies every asset under the source environment's prefix into the current environment.
  `source_environment` is a full environment name, e.g. `screens-dev`.
  A local backup has no corresponding set of assets in S3, so this function is a no-op
  when the source or destination environment is `screens-local`.
  """
  @spec sync(String.t()) :: {:ok, result()} | {:error, term()}
  def sync("screens-local"), do: {:ok, %{copied: 0}}

  def sync(source_environment) do
    destination = Application.get_env(:screens, :environment_name)

    if destination == "screens-local" do
      {:ok, %{copied: 0}}
    else
      do_sync(source_environment, destination)
    end
  end

  defp do_sync(source_environment, destination) do
    prefix = source_environment <> "/"

    @bucket
    |> S3.list_objects_v2(prefix: prefix)
    |> ExAws.stream!()
    |> Stream.map(& &1.key)
    |> Stream.reject(&skip?(&1, prefix))
    |> Task.async_stream(&copy(&1, prefix, destination),
      max_concurrency: @max_concurrency,
      # Default Cowboy timeout is 60 seconds, so this should be safe
      timeout: 60000
    )
    |> Enum.reduce_while({:ok, 0}, fn
      {:ok, :ok}, {:ok, count} ->
        {:cont, {:ok, count + 1}}

      {:ok, {:error, _} = error}, _acc ->
        {:halt, error}
    end)
    |> case do
      {:ok, count} -> {:ok, %{copied: count}}
      {:error, _} = error -> error
    end
  end

  defp skip?(key, prefix) do
    String.ends_with?(key, "/") or String.replace_prefix(key, prefix, "") in @excluded_keys
  end

  defp copy(key, prefix, destination) do
    destination_key = String.replace_prefix(key, prefix, destination <> "/")

    copy_operation =
      S3.put_object_copy(@bucket, destination_key, @bucket, key,
        acl: :public_read,
        metadata_directive: "COPY"
      )

    case ExAws.request(copy_operation) do
      {:ok, %{status_code: 200}} -> :ok
      error -> {:error, {:asset_copy_failed, key, error}}
    end
  end
end
