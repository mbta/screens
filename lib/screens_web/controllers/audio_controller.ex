defmodule ScreensWeb.AudioController do
  use ScreensWeb, :controller
  require Logger
  alias Phoenix.View

  @fallback_audio_path "assets/static/audio/readout_fallback.mp3"

  def show(conn, %{"id" => screen_id} = params) do
    disposition =
      params
      |> Map.get("disposition")
      |> disposition_atom()

    is_screen = ScreensWeb.UserAgent.is_screen_conn?(conn)

    _ = Screens.LogScreenData.log_audio_request(screen_id, is_screen)

    with {:ok, ssml} <- render_ssml(screen_id, is_screen),
         {:ok, audio_data} <- Screens.Audio.synthesize(ssml) do
      send_audio(conn, {:binary, audio_data}, disposition)
    else
      _ -> send_audio(conn, {:file, @fallback_audio_path}, disposition)
    end
  end

  def debug(conn, %{"id" => screen_id}) do
    case render_ssml(screen_id, false) do
      {:ok, ssml} -> text(conn, ssml)
      _ -> text(conn, "Failed to load data")
    end
  end

  defp render_ssml(screen_id, is_screen) do
    data = Screens.ScreenData.by_screen_id(screen_id, is_screen)

    case data do
      %{success: true} ->
        template_assigns = Screens.Audio.from_api_data(data)
        {:ok, View.render_to_string(ScreensWeb.AudioView, "index.ssml", template_assigns)}

      _ ->
        :error
    end
  end

  defp send_audio(conn, kind, disposition) do
    send_download(conn, kind, filename: "readout.mp3", disposition: disposition)
  end

  defp disposition_atom("inline"), do: :inline
  defp disposition_atom(_), do: :attachment
end
