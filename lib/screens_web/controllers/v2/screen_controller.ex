defmodule ScreensWeb.V2.ScreenController do
  use ScreensWeb, :controller

  def index(conn, %{"id" => _screen_id}) do
    conn
    |> put_view(ScreensWeb.V2.ScreenView)
    |> put_layout({ScreensWeb.V2.LayoutView, "app.html"})
    |> render("index.html")
  end
end
