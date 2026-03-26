defmodule ScreensWeb.V2.AudioController do
  use ScreensWeb, :controller
  require Logger

  alias Phoenix.View
  alias Screens.Config.Cache
  alias Screens.V2.ScreenAudioData
  alias ScreensWeb.Plug.{LegacyLogging, ScreenRequest}

  plug LegacyLogging, :audio when action == :show
  plug ScreenRequest when action in [:show, :show_volume, :debug]

  def show(%{assigns: %{screen_id: screen_id}} = conn, params) do
    disposition = if Map.has_key?(params, "inline"), do: :inline, else: :attachment

    cond do
      Cache.disabled?(screen_id) -> not_found(conn)
      true -> readout(conn, screen_id, disposition)
    end
  end

  def show_volume(%{assigns: %{screen_id: screen_id}} = conn, _params) do
    cond do
      Cache.disabled?(screen_id) ->
        json(conn, %{volume: 0.0})

      true ->
        {:ok, volume} = ScreenAudioData.volume_by_screen_id(screen_id)
        json(conn, %{volume: volume})
    end
  end

  def debug(%{assigns: %{screen_id: screen_id}} = conn, _params) do
    cond do
      Cache.disabled?(screen_id) -> text(conn, "Screen #{screen_id} is disabled.")
      true -> text(conn, fetch_ssml(screen_id))
    end
  end

  defp readout(conn, screen_id, disposition) do
    screen_id
    |> fetch_ssml()
    |> Screens.Audio.synthesize()
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
    View.render_to_string(
      ScreensWeb.V2.AudioView,
      "index.ssml",
      widget_audio_data: ScreenAudioData.by_screen_id(screen_id)
    )
  end

  defp not_found(conn) do
    send_resp(conn, 404, "Not found")
  end
end
