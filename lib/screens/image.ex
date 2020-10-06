defmodule Screens.Image do
  @moduledoc false

  alias ExAws.S3

  @bucket "mbta-screens"
  @psa_images_prefix Application.get_env(:screens, :environment_name, "dev") <> "/images/psa/"

  # Matches all non-delimiter characters located after the last delimiter.
  # screens/images/psa/some-image_file-3.png
  #                    ^^^^^^^^^^^^^^^^^^^^^
  @image_filename_pattern ~r|([^/]*)$|

  @typep s3_object :: %{
           e_tag: String.t(),
           key: String.t(),
           last_modified: String.t(),
           owner: %{display_name: String.t(), id: String.t()},
           size: String.t(),
           storage_class: String.t()
         }

  @spec fetch_image_filenames() :: list(String.t())
  def fetch_image_filenames do
    list_operation = S3.list_objects(@bucket, prefix: @psa_images_prefix)

    list_operation
    |> ExAws.stream!()
    |> Stream.reject(&directory?/1)
    |> Stream.map(&get_image_filename/1)
    |> Enum.to_list()
  end

  @spec upload_image(Plug.Upload.t()) :: {:ok, String.t()} | :error
  def upload_image(%Plug.Upload{filename: filename, path: local_path, content_type: content_type}) do
    filename = String.downcase(filename)
    s3_path = @psa_images_prefix <> filename

    result =
      local_path
      |> S3.Upload.stream_file()
      |> S3.upload(@bucket, s3_path, acl: :public_read, content_type: content_type)
      |> ExAws.request()

    case result do
      {:ok, %{status_code: 200}} -> {:ok, filename}
      _ -> :error
    end
  end

  @spec delete_image(String.t()) :: :ok | :error
  def delete_image(filename) do
    s3_path = @psa_images_prefix <> filename
    delete_operation = S3.delete_object(@bucket, s3_path)

    case ExAws.request(delete_operation) do
      {:ok, %{status_code: 204}} -> :ok
      _ -> :error
    end
  end

  @spec get_image_filename(s3_object) :: String.t()
  defp get_image_filename(obj) do
    @image_filename_pattern
    |> Regex.run(obj.key, capture: :all_but_first)
    |> hd()
  end

  @spec directory?(s3_object) :: boolean()
  defp directory?(obj) do
    String.ends_with?(obj.key, "/")
  end
end
