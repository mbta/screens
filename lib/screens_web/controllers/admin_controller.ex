defmodule ScreensWeb.AdminController do
  use ScreensWeb, :controller

  def index(conn, _) do
    conn
    |> assign(:app_id, "admin")
    |> put_layout("admin.html")
    |> render("admin.html")
  end
end
