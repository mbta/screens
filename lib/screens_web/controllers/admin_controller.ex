defmodule ScreensWeb.AdminController do
  use ScreensWeb, :controller

  def index(conn, _) do
    conn
    |> assign(:app_id, "admin")
    |> put_layout(html: {ScreensWeb.LayoutView, :admin})
    |> render(:admin)
  end
end
