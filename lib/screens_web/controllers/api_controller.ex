defmodule ScreensWeb.ApiController do
  use ScreensWeb, :controller

  def show(conn, %{"id" => id}) do
    screens_data = Application.get_env(:screens, :screen_data)
    screen_data = Map.get(screens_data, id)

    json(conn, %{screen_id: id, stop_id: Map.get(screen_data, :stop_id)})
  end
end
