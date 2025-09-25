defmodule ScreensWeb.AdminController do
  use ScreensWeb, :controller

  def index(conn, _) do
    conn |> assign(:app_id, "admin") |> render(:admin)
  end
end
