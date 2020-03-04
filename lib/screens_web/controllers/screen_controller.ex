defmodule ScreensWeb.ScreenController do
  use ScreensWeb, :controller

  plug(:api_version)

  defp api_version(conn, _) do
    api_version = Application.get_env(:screens, :api_version)
    assign(conn, :api_version, api_version)
  end

  def index(conn, %{"id" => screen_id}) do
    app_id =
      :screens
      |> Application.get_env(:screen_data)
      |> Map.get(screen_id)
      |> Map.get(:app_id)

    conn
    |> assign(:app_id, app_id)
    |> render("index.html")
  end
end
