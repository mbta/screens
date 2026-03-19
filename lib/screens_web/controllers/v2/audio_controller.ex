defmodule ScreensWeb.V2.AudioController do
  use ScreensWeb, :controller
  require Logger

  alias Phoenix.View
  alias Screens.V2.ScreenAudioData
  alias ScreensConfig.Screen
  alias ScreensWeb.Plug.{LegacyLogging, ScreenRequest}

  plug ScreenRequest, [type: :audio] when action == :show
  plug ScreenRequest, [type: :volume] when action == :show_volume
  plug ScreenRequest when action == :debug
  plug LegacyLogging, :audio when action == :show

  def show(%{assigns: %{screen: %Screen{disabled: true}}} = conn, _params), do: not_found(conn)

  def show(%{assigns: %{screen: screen}} = conn, params) do
    disposition = if Map.has_key?(params, "inline"), do: :inline, else: :attachment

    screen
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

  def show_volume(%{assigns: %{screen: %Screen{disabled: true}}} = conn, _params),
    do: json(conn, %{volume: 0.0})

  def show_volume(%{assigns: %{screen: screen}} = conn, _params) do
    {:ok, volume} = ScreenAudioData.get_volume(screen)
    json(conn, %{volume: volume})
  end

  def debug(%{assigns: %{screen: screen}} = conn, _params) do
    text(conn, fetch_ssml(screen))
  end

  defp fetch_ssml(screen) do
    View.render_to_string(
      ScreensWeb.V2.AudioView,
      "index.ssml",
      widget_audio_data: ScreenAudioData.get(screen)
    )
  end

  defp not_found(conn) do
    send_resp(conn, 404, "Not found")
  end
end
