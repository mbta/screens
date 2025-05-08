defmodule Screens.Image do
  @moduledoc false

  alias ExAws.S3

  @bucket "mbta-screens"
  @base_uri "https://#{@bucket}.s3.amazonaws.com/"

  # How long to reuse cached assets before checking whether they're still fresh.
  @max_age_mins 15
  # How long after max-age has expired to continue reusing cached assets while checking whether
  # they're still fresh in the background.
  @swr_mins 5

  @cache_control "max-age=#{@max_age_mins * 60}, stale-while-revalidate=#{@swr_mins * 60}"

  @spec list() :: list(%{key: String.t(), url: String.t()})
  def list do
    @bucket
    |> S3.list_objects_v2(prefix: images_prefix())
    |> ExAws.stream!()
    |> Stream.map(& &1.key)
    |> Stream.reject(&prefix?/1)
    |> Stream.map(
      &%{
        key: String.replace(&1, images_prefix() <> "/", ""),
        url: @base_uri |> URI.merge(&1) |> URI.to_string()
      }
    )
    |> Enum.to_list()
  end

  @spec upload(String.t(), Plug.Upload.t()) :: :ok | :error
  def upload(key, %Plug.Upload{path: local_path, content_type: content_type}) do
    result =
      local_path
      |> S3.Upload.stream_file()
      |> S3.upload(@bucket, image_path(key),
        acl: :public_read,
        cache_control: @cache_control,
        content_type: content_type
      )
      |> ExAws.request()

    case result do
      {:ok, %{status_code: 200}} -> :ok
      _ -> :error
    end
  end

  @spec delete(String.t()) :: :ok | :error
  def delete(key) do
    case @bucket |> S3.delete_object(image_path(key)) |> ExAws.request() do
      {:ok, %{status_code: 204}} -> :ok
      _ -> :error
    end
  end

  defp images_prefix do
    Path.join(Application.get_env(:screens, :environment_name, "screens-dev"), "images")
  end

  defp image_path(key), do: Path.join(images_prefix(), key)

  defp prefix?(key), do: String.ends_with?(key, "/")
end
