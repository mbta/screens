defmodule ScreensWeb.AudioController do
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
      |> send_audio({:file, @fallback_audio_path}, disposition: :attachment)
      |> halt()
    end
  end

  defp screen_exists?(screen_id) do
    not is_nil(State.screen(screen_id))
  end

  def show(conn, %{"id" => screen_id} = params) do
    disposition =
      params
      |> Map.get("disposition")
      |> disposition_atom()

    is_screen = ScreensWeb.UserAgent.is_screen_conn?(conn, screen_id)

    _ = Screens.LogScreenData.log_audio_request(screen_id, is_screen)

    with true <- screen_exists?(screen_id),
         %{success: true} = data <-
           Screens.ScreenData.by_screen_id(screen_id, is_screen, check_disabled: true),
         template_assigns <- Screens.Audio.from_api_data(data, screen_id),
         ssml <- render_ssml(template_assigns),
         {:ok, audio_data} <- Screens.Audio.synthesize(ssml, is_screen) do
      send_audio(conn, {:binary, audio_data}, disposition)
    else
      _ -> send_fallback_audio(conn, is_screen, screen_id, disposition)
    end
  end

  def debug(conn, %{"id" => screen_id}) do
    with true <- screen_exists?(screen_id),
         %{success: true} = data <- Screens.ScreenData.by_screen_id(screen_id, false),
         template_assigns <- Screens.Audio.from_api_data(data, screen_id),
         ssml <- render_ssml(template_assigns) do
      text(conn, ssml)
    else
      _ -> text(conn, "Failed to load data")
    end
  end

  defp render_ssml(template_assigns) do
    View.render_to_string(ScreensWeb.AudioView, "index.ssml", template_assigns)
  end

  defp send_fallback_audio(conn, is_screen, screen_id, disposition) do
    _ =
      if is_screen do
        Logger.info("fallback_audio #{screen_id}")
      end

    send_audio(conn, {:file, @fallback_audio_path}, disposition)
  end

  defp send_audio(conn, kind, disposition) do
    send_download(conn, kind, filename: "readout.mp3", disposition: disposition)
  end

  defp disposition_atom("inline"), do: :inline
  defp disposition_atom(_), do: :attachment
end
