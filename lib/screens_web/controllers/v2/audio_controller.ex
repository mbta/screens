defmodule ScreensWeb.V2.AudioController do
  use ScreensWeb, :controller
  require Logger

  alias Phoenix.View
  alias Screens.Config.State
  alias Screens.V2.ScreenAudioData

  plug(:check_config)

  defp check_config(conn, _) do
    if State.ok?(), do: conn, else: not_found(conn)
  end

  def show(conn, %{"id" => screen_id} = params) do
    real_screen? = Map.get(params, "is_real_screen", false)
    disposition = if Map.has_key?(params, "inline"), do: :inline, else: :attachment

    cond do
      not screen_exists?(screen_id) -> not_found(conn)
      State.disabled?(screen_id) -> disabled(conn)
      true -> readout(conn, screen_id, real_screen?, disposition)
    end
  end

  def show_volume(conn, %{"id" => screen_id}) do
    cond do
      not screen_exists?(screen_id) ->
        not_found(conn)

      State.disabled?(screen_id) ->
        json(conn, %{volume: 0.0})

      true ->
        {:ok, volume} = ScreenAudioData.volume_by_screen_id(screen_id)
        json(conn, %{volume: volume})
    end
  end

  def debug(conn, %{"id" => screen_id}) do
    cond do
      not screen_exists?(screen_id) -> not_found(conn)
      State.disabled?(screen_id) -> text(conn, "Screen #{screen_id} is disabled.")
      true -> text(conn, fetch_ssml(screen_id))
    end
  end

  def text_to_speech(conn, %{"text" => text}) do
    case Screens.Audio.synthesize(text, false, "text") do
      {:ok, audio_data} ->
        send_download(conn, {:binary, audio_data}, filename: "readout.mp3", disposition: :inline)

      :error ->
        not_found(conn)
    end
  end

  defp readout(conn, screen_id, real_screen?, disposition) do
    screen_id
    |> fetch_ssml()
    |> Screens.Audio.synthesize(real_screen?, "ssml")
    |> case do
      {:ok, audio_data} ->
        send_download(conn, {:binary, audio_data},
          filename: "readout.mp3",
          disposition: disposition
        )

      :error ->
        not_found(conn)
    end
  end

  defp fetch_ssml(screen_id) do
    widget_audio_data = ScreenAudioData.by_screen_id(screen_id)

    render_ssml(widget_audio_data: widget_audio_data)
  end

  defp render_ssml(template_assigns) do
    View.render_to_string(ScreensWeb.V2.AudioView, "index.ssml", template_assigns)
  end

  defp disabled(conn) do
    not_found(conn)
  end

  defp not_found(conn) do
    send_resp(conn, 404, "Not found")
  end

  defp screen_exists?(screen_id) do
    not is_nil(State.screen(screen_id))
  end
end
