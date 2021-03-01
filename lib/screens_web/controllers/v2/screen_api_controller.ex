defmodule ScreensWeb.V2.ScreenApiController do
  use ScreensWeb, :controller

  def show(conn, %{"id" => screen_id}) do
    data = Screens.V2.ScreenData.by_screen_id(screen_id)
    json(conn, data)
  end
end
