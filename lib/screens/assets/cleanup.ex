defmodule Screens.Assets.Cleanup do
  @moduledoc """
  Removes unreferenced assets from the current environment in the S3 bucket.
  Only images/ and video/ are considered. Objects modified within the grace period
  and within the reusable/ subdirectories are retained. References are collected from every
  configuration value, including disabled screens.
  """

  alias ExAws.S3
  alias Screens.Config.ScreenConfig
  alias Screens.Util.Assets

  @bucket "mbta-screens"
  @media_directories ~w[images videos]

  # We won't delete assets in the this subdirectory
  @reusable_subdirectory "reusable/"
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
          {directories, files} = Enum.split_with(objects, &String.ends_with?(&1.key, "/"))

          # First pass: find eligible non-directory objects
          eligible_files =
            files
            |> Enum.filter(&eligible_file?(&1, prefix, environment, references, cutoff))
            |> MapSet.new(&Map.get(&1, :key))

          # Second pass: find empty directories (those with no remaining children after planned deletion)
          all_files = MapSet.new(Enum.map(files, &Map.get(&1, :key)))

          eligible_directories =
            directories
            |> Enum.filter(&eligible_dir?(&1, all_files, eligible_files, prefix))
            |> Enum.map(& &1.key)

          eligible = (MapSet.to_list(eligible_files) ++ eligible_directories) |> Enum.uniq()

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
    # Omit continuation token on first request. For each subsequent page, use the previous
    # response's next_continuation_token until is_truncated is "false" indicating the last page
    opts = [prefix: prefix] ++ if(token, do: [continuation_token: token], else: [])

    case request.(S3.list_objects_v2(@bucket, opts)) do
      {:ok, %{body: %{contents: objects, is_truncated: truncated} = body}} ->
        if truncated == "true" do
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

  @spec eligible_file?(map(), String.t(), String.t(), map(), DateTime.t()) :: boolean()
  defp eligible_file?(%{key: key, last_modified: modified}, prefix, env, configured_files, cutoff)
       when is_binary(key) and is_binary(modified) do
    with true <- String.starts_with?(key, prefix),
         false <- String.starts_with?(key, prefix <> @reusable_subdirectory),
         false <- Map.has_key?(configured_files, relative_path(key, env)),
         {:ok, modified, _offset} <- DateTime.from_iso8601(modified) do
      DateTime.compare(modified, cutoff) == :lt
    else
      _ -> false
    end
  end

  defp eligible_file?(_object, _prefix, _env, _configured_files, _cutoff), do: false

  @spec eligible_dir?(map(), MapSet.t(String.t()), MapSet.t(String.t()), String.t()) :: boolean()
  defp eligible_dir?(%{key: key, last_modified: modified}, all_files, eligible_files, prefix)
       when is_binary(key) and is_binary(modified) do
    with true <- String.starts_with?(key, prefix),
         false <- key == prefix,
         false <- String.starts_with?(key, prefix <> @reusable_subdirectory) do
      # Directory is eligible only if all its children will be deleted
      Enum.all?(all_files, fn obj_key ->
        not String.starts_with?(obj_key, key) or MapSet.member?(eligible_files, obj_key)
      end)
    else
      _ -> false
    end
  end

  defp eligible_dir?(_object, _all_files, _eligible_files, _prefix), do: false

  # Traverse values rather than known schema fields, to future-proof for new widgets.
  defp strings(value) when is_binary(value), do: [value]
  defp strings(value) when is_map(value), do: value |> Map.values() |> Enum.flat_map(&strings/1)
  defp strings(value) when is_list(value), do: Enum.flat_map(value, &strings/1)
  defp strings(_value), do: []

  defp reference_paths(value, environment) do
    host = Assets.s3_asset_host()

    case URI.parse(value) do
      %URI{host: ^host, path: path} when is_binary(path) ->
        relative = String.replace_prefix(path, "/#{environment}/", "")
        [relative, decode_and_normalize(relative)]

      _ ->
        [value, decode_and_normalize(value)]
    end
  end

  defp decode_and_normalize(value) do
    # To normalize asset names from configurations to match the names stored in S3,
    # decode percent-encoded characters and replace + with space
    value |> URI.decode() |> String.replace("+", " ")
  end

  defp relative_path(key, env) do
    String.replace_prefix(key, env <> "/", "")
  end
end
