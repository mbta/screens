defmodule ScreensWeb.AdminController do
  use ScreensWeb, :controller

  def index(conn, _) do
    conn
    |> assign(:app_id, "admin")
    |> assign(:environment_name, environment_name())
    |> render(:admin)
  end

  defp environment_name, do: Application.get_env(:screens, :environment_name, "screens-local")
end
