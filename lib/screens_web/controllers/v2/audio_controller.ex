defmodule ScreensWeb.V2.AudioController do
  use ScreensWeb, :controller
  require Logger
  alias Screens.Config.State

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
      {:ok, audio_data} ->
        send_download(conn, {:binary, audio_data}, filename: "readout.mp3", disposition: :inline)

      :error ->
        send_resp(conn, 404, "Not found")
    end
  end
end
