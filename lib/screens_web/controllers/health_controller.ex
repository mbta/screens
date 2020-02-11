defmodule ScreensWeb.HealthController do
  use ScreensWeb, :controller

  def index(conn, _params) do
    send_resp(conn, 200, "")
  end
end
