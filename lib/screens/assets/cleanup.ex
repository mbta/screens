defmodule Screens.Assets.Cleanup do
  @moduledoc """
  Removes unreferenced assets from the current environment in the S3 bucket.
  Only images/ and video/ are considered. Objects modified within the grace period
  and within the reusable/ subdirectories are retained. References are collected from every
  configuration value, including disabled screens.
  """

  alias ExAws.S3
  alias Screens.Config.ScreenConfig

  @bucket "mbta-screens"
  @media_directories ~w[images videos]
  # 30 days in seconds - we won't delete assets modified within this period
  @grace_period_seconds 30 * 24 * 60 * 60

  @callback preview([ScreenConfig.t()]) :: {:ok, [String.t()]} | {:error, term()}
  @callback delete([ScreenConfig.t()], [String.t()]) ::
              {:ok, non_neg_integer()} | {:error, term()}

  @doc "Lists eligible S3 keys without deleting anything. S3 requests and time can be injected in tests."
  @spec preview([ScreenConfig.t()], keyword(), DateTime.t()) ::
          {:ok, [String.t()]} | {:error, term()}
  def preview(configs, opts \\ [], now \\ DateTime.utc_now()) do
    request = Keyword.get(opts, :request, &ExAws.request/1)
    environment = Application.fetch_env!(:screens, :environment_name)

    references =
      configs
      |> strings()
      |> Enum.flat_map(&reference_paths(&1, environment))
      |> Map.new(&{&1, true})

    cutoff = DateTime.add(now, -@grace_period_seconds)

    Enum.reduce_while(@media_directories, {:ok, []}, fn directory, {:ok, keys} ->
      prefix = "#{environment}/#{directory}/"

      case list_objects(prefix, request) do
        {:ok, objects} ->
          eligible =
            objects
            |> Enum.filter(&eligible?(&1, prefix, environment, references, cutoff))
            |> Enum.map(& &1.key)

          {:cont, {:ok, eligible ++ keys}}

        {:error, _} = error ->
          {:halt, error}
      end
    end)
    |> case do
      {:ok, keys} -> {:ok, Enum.sort(keys)}
      error -> error
    end
  end

  @doc "Rechecks eligibility and deletes only keys included in the confirmed preview."
  @spec delete([ScreenConfig.t()], [String.t()], keyword(), DateTime.t()) ::
          {:ok, non_neg_integer()} | {:error, term()}
  def delete(configs, keys, opts \\ [], now \\ DateTime.utc_now()) do
    request = Keyword.get(opts, :request, &ExAws.request/1)
    confirmed = Map.new(keys, &{&1, true})

    with {:ok, eligible} <- preview(configs, opts, now) do
      eligible
      |> Enum.filter(&Map.has_key?(confirmed, &1))
      |> Enum.reduce_while({:ok, 0}, fn key, {:ok, deleted} ->
        case request.(S3.delete_object(@bucket, key)) do
          {:ok, %{status_code: 204}} -> {:cont, {:ok, deleted + 1}}
          error -> {:halt, {:error, {:asset_delete_failed, key, error, deleted}}}
        end
      end)
    end
  end

  defp list_objects(prefix, request, token \\ nil, acc \\ []) do
    opts = [prefix: prefix] ++ if(token, do: [continuation_token: token], else: [])

    case request.(S3.list_objects_v2(@bucket, opts)) do
      {:ok, %{body: %{contents: objects, is_truncated: truncated} = body}} ->
        if truncated in [true, "true"] do
          case Map.get(body, :next_continuation_token) do
            next when is_binary(next) and next != "" and next != token ->
              list_objects(prefix, request, next, objects ++ acc)

            _ ->
              {:error, :missing_continuation_token}
          end
        else
          {:ok, objects ++ acc}
        end

      error ->
        {:error, {:asset_listing_failed, prefix, error}}
    end
  end

  defp eligible?(%{key: key, last_modified: modified}, prefix, environment, references, cutoff)
       when is_binary(key) and is_binary(modified) do
    relative = String.replace_prefix(key, environment <> "/", "")

    with true <- String.starts_with?(key, prefix),
         false <- String.ends_with?(key, "/"),
         false <- String.starts_with?(key, prefix <> "reusable/"),
         false <- Map.has_key?(references, relative),
         {:ok, modified, _offset} <- DateTime.from_iso8601(modified) do
      DateTime.compare(modified, cutoff) == :lt
    else
      _ -> false
    end
  end

  defp eligible?(_object, _prefix, _environment, _references, _cutoff), do: false

  # Traverse values rather than known schema fields, to future-proof for  new widgets.
  defp strings(value) when is_binary(value), do: [value]
  defp strings(value) when is_map(value), do: value |> Map.values() |> Enum.flat_map(&strings/1)
  defp strings(value) when is_list(value), do: Enum.flat_map(value, &strings/1)
  defp strings(_value), do: []

  defp reference_paths(value, environment) do
    case URI.parse(value) do
      %URI{host: "mbta-screens.s3.amazonaws.com", path: path} when is_binary(path) ->
        relative = String.replace_prefix(path, "/#{environment}/", "")
        [relative, URI.decode(relative)]

      _ ->
        [value, URI.decode(value)]
    end
  end
end
