defmodule Screens.Audio do
  @moduledoc false

  alias Screens.Report

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
        Report.error("synthesize_ssml_failed", [error: error, string: ssml_string] ++ log_meta)
        :error
    end
  end
end
