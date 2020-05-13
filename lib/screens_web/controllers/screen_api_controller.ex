defmodule ScreensWeb.ScreenApiController do
  use ScreensWeb, :controller
  require Logger

  def show(conn, %{"id" => screen_id, "version" => _version, "date" => date, "time" => time}) do
    data = Screens.ScreenData.by_screen_id_with_datetime(screen_id, date, time)

    json(conn, data)
  end

  def show(conn, %{"id" => screen_id, "version" => version}) do
    is_screen = ScreensWeb.UserAgent.is_screen_conn?(conn)

    _ =
      if is_screen do
        Logger.info("[screen data request] screen_id=#{screen_id} version=#{version}")
      end

    data =
      Screens.ScreenData.by_screen_id_with_override_and_version(screen_id, version, is_screen)

    json(conn, data)
  end
end
