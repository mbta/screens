defmodule Screens.Audio.Fetch do
  @moduledoc false

  require Logger

  def fetch_psa({format, name, type}) do
    case get_from_s3(name, format) do
      {:ok, psa_text} -> {format, psa_text, type}
      :error -> nil
    end
  end

  def get_from_s3(name, format) do
    bucket = Application.get_env(:screens, :audio_psa_s3_bucket)

    get_operation = ExAws.S3.get_object(bucket, psa_path(name, format))

    case ExAws.request(get_operation) do
      {:ok, %{body: body, status_code: 200}} ->
        {:ok, body}

      {:error, err} ->
        _ = Logger.info("s3_audio_psa_fetch_error #{inspect(err)}")
        :error
    end
  end

  defp psa_path(name, format) do
    Application.get_env(:screens, :audio_psa_s3_directory) <>
      name <> format_to_file_extension(format)
  end

  defp format_to_file_extension(:plaintext), do: ".txt"
  defp format_to_file_extension(:ssml), do: ".ssml"
end
