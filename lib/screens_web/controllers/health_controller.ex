defmodule ScreensWeb.HealthController do
  use ScreensWeb, :controller

  plug Logster.ChangeConfig, status_2xx_level: :debug

  def index(conn, _params) do
    send_resp(conn, 200, "")
  end
end
