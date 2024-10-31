defmodule Screens.Audio do
  @moduledoc false

  require Logger

  @lexicon_names ["mbtalexicon"]

  @spec synthesize(String.t(), keyword()) :: {:ok, binary()} | :error
  def synthesize(ssml_string, log_meta) do
    result =
      ssml_string
      |> ExAws.Polly.synthesize_speech(lexicon_names: @lexicon_names, text_type: "ssml")
      |> ExAws.request()

    case result do
      {:ok, %{body: audio_data}} ->
        {:ok, audio_data}

      {:error, error} ->
        report_error(ssml_string, error, log_meta)
        :error
    end
  end

  defp report_error(ssml_string, error, meta) do
    Logger.error(
      "synthesize_ssml_failed string=#{inspect(ssml_string)} error=#{inspect(error)}",
      meta
    )

    _ =
      if meta[:is_screen] do
        Sentry.capture_message("synthesize_ssml_failed",
          extra: Enum.into(meta, %{error: error, string: ssml_string})
        )
      end

    nil
  end
end
