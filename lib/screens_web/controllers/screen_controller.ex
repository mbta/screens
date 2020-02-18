defmodule ScreensWeb.ScreenController do
  use ScreensWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
