defmodule ScreensWeb.V2.ScreenApiController do
  use ScreensWeb, :controller

  alias Screens.Config.State

  plug(:check_config)

  defp check_config(conn, _) do
    if State.ok?() do
      conn
    else
      conn
      |> put_status(:not_found)
      |> halt()
    end
  end

  def show(conn, %{"id" => screen_id, "last_refresh" => last_refresh}) do
    is_screen = ScreensWeb.UserAgent.is_screen_conn?(conn, screen_id)

    _ = Screens.LogScreenData.log_data_request(screen_id, last_refresh, is_screen)

    data = Screens.V2.ScreenData.by_screen_id(screen_id, last_refresh)
    json(conn, data)
  end
end
