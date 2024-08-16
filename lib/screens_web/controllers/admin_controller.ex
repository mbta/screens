defmodule ScreensWeb.AdminController do
  use ScreensWeb, :controller

  def index(conn, _) do
    conn
    |> assign(:app_id, "admin")
    |> put_layout(html: {ScreensWeb.V2.LayoutView, :app})
    |> render(:admin)
  end
end
