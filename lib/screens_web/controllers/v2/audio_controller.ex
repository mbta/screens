defmodule ScreensWeb.V2.AudioController do
  use ScreensWeb, :controller
  require Logger
  alias Phoenix.View
  alias Screens.Config.State

  @fallback_audio_path "assets/static/audio/readout_fallback.mp3"

  plug(:check_config)

  defp check_config(conn, _) do
    if State.ok?() do
      conn
    else
      conn
      |> put_status(:not_found)
      |> halt()
    end
  end

  def text_to_speech(conn, %{"text" => text}) do
    case Screens.Audio.synthesize(text, false, "text") do
        {:ok, audio_data} -> send_download(conn, {:binary, audio_data}, filename: "readout.mp3", disposition: :inline)
        :error -> send_download(conn, {:file, @fallback_audio_path}, filename: "readout.mp3", disposition: :inline)
      end
  end
end
