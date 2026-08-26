defmodule ScreensWeb.V2.AudioController do
  use ScreensWeb, :controller

  alias Phoenix.View
  alias Screens.V2.ScreenData
  alias Screens.V2.ScreenData.Parameters
  alias ScreensConfig.EmergencyTakeover
  alias ScreensConfig.Screen
  alias ScreensWeb.Plug.ScreenRequest

  plug ScreenRequest, [type: :audio] when action == :show
  plug ScreenRequest, [type: :volume] when action == :show_volume
  plug ScreenRequest when action == :debug

  def show(%{assigns: %{screen: %Screen{disabled: true}}} = conn, _params), do: not_found(conn)

  def show(
        %{
          assigns: %{
            screen: %Screen{
              app_params: %_app{
                emergency_takeover: %EmergencyTakeover{audio_asset_path: audio_asset_path}
              }
            }
          }
        } = conn,
        _params
      )
      when audio_asset_path != nil do
    redirect(conn, external: audio_asset_path)
  end

  def show(%{assigns: %{screen_id: id, screen: screen}} = conn, params) do
    with true <- Parameters.audio_enabled?(screen, now(conn)),
         {:ok, audio} <- fetch_ssml(id, screen) |> Screens.Audio.synthesize() do
      disposition = if Map.has_key?(params, "inline"), do: :inline, else: :attachment
      send_download(conn, {:binary, audio}, filename: "readout.mp3", disposition: disposition)
    else
      _ ->
        not_found(conn)
    end
  end

  def show_volume(%{assigns: %{screen: %Screen{disabled: true}}} = conn, _params),
    do: json(conn, %{volume: 0.0})

  def show_volume(%{assigns: %{screen: screen}} = conn, _params),
    do: json(conn, %{volume: Parameters.audio_volume(screen, now(conn))})

  def debug(%{assigns: %{screen_id: id, screen: screen}} = conn, _params) do
    text(conn, fetch_ssml(id, screen))
  end

  defp fetch_ssml(id, screen) do
    View.render_to_string(
      ScreensWeb.V2.AudioView,
      "index.ssml",
      widget_audio_data: ScreenData.audio(id, screen)
    )
  end

  defp not_found(conn) do
    send_resp(conn, 404, "Not found")
  end

  defp now(%{assigns: %{now: now}}), do: now
  # This is equivalent to an argument with a default value
  # credo:disable-for-next-line Screens.Checks.UntestableDateTime
  defp now(_conn), do: DateTime.utc_now()
end
