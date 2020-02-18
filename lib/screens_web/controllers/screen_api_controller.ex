defmodule ScreensWeb.ScreenApiController do
  use ScreensWeb, :controller

  def show(conn, %{"id" => screen_id}) do
    data =
      :screens
      |> Application.get_env(:screen_data)
      |> Map.get(screen_id)
      |> Map.get(:stop_id)
      |> Screens.ScreenData.by_stop_id()

    json(conn, data)
  end
end
