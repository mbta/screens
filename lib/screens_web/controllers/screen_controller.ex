defmodule ScreensWeb.ScreenController do
  use ScreensWeb, :controller

  plug(:api_version)

  defp api_version(conn, _) do
    api_version = Application.get_env(:screens, :api_version)
    assign(conn, :api_version, api_version)
  end

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
