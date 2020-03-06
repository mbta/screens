defmodule ScreensWeb.ScreenApiController do
  use ScreensWeb, :controller

  def show(conn, %{"id" => screen_id, "version" => version}) do
    data =
      :screens
      |> Application.get_env(:screen_data)
      |> Map.get(screen_id)
      |> Map.get(:stop_id)
      |> Screens.ScreenData.by_stop_id_with_override_and_version(screen_id, version)

    json(conn, data)
  end
end
