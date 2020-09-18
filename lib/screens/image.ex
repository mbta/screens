defmodule Screens.Image do
  @moduledoc false

  alias ExAws.S3

  @bucket "mbta-dotcom"
  @psa_images_prefix "screens/images/psa/"

  # Matches all non-delimiter characters located before the file extension and after the last delimiter.
  # screens/images/psa/some-image_file-3.png
  #                    ^^^^^^^^^^^^^^^^^
  @image_name_pattern ~r|([^/]*)\.png$|

  def fetch_image_names do
    list_operation = S3.list_objects(@bucket, prefix: @psa_images_prefix)

    list_operation
    |> ExAws.stream!()
    |> Enum.map(&s3_path_to_image_name/1)
  end

  def upload_image(%Plug.Upload{filename: filename, path: path}) do
    filename = String.downcase(filename)

    result =
      path
      |> S3.Upload.stream_file()
      |> S3.upload(@bucket, @psa_images_prefix <> filename)
      |> ExAws.request()

    case result do
      {:ok, %{status_code: 200}} -> {:ok, filename}
      _ -> :error
    end
  end

  def delete_image(image_name) do
    delete_operation = S3.delete_object(@bucket, @psa_images_prefix <> image_name)

    case ExAws.request(delete_operation) do
      {:ok, %{status_code: 200}} -> :ok
      _ -> :error
    end
  end

  defp s3_path_to_image_name(path) do
    @image_name_pattern
    |> Regex.run(path, capture: :all_but_first)
    |> hd()
  end
end
