defmodule ScreensWeb.ScreenApiController do
  use ScreensWeb, :controller
  require Logger

  def show(conn, %{"id" => screen_id, "version" => version}) do
    %{app_id: app_id, stop_id: stop_id} =
      :screens
      |> Application.get_env(:screen_data)
      |> Map.get(screen_id)

    is_screen = ScreensWeb.UserAgent.is_screen_conn?(conn)

    _ =
      if is_screen do
        Logger.info("[screen data request] screen_id=#{screen_id} version=#{version}")
      end

    data =
      case app_id do
        "bus_eink" ->
          Screens.ScreenData.by_stop_id_with_override_and_version(
            stop_id,
            screen_id,
            version,
            is_screen
          )

        "gl_eink_single" ->
          Screens.GLScreenData.by_stop_id_with_override_and_version(
            stop_id,
            screen_id,
            version,
            is_screen
          )

        "gl_eink_double" ->
          Screens.GLScreenData.by_stop_id_with_override_and_version(
            stop_id,
            screen_id,
            version,
            is_screen
          )
      end

    json(conn, data)
  end
end
