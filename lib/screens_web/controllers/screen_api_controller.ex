defmodule ScreensWeb.ScreenApiController do
  use ScreensWeb, :controller
  require Logger
  alias Screens.Config.Cache

  plug(:check_config)

  defp check_config(conn, _) do
    if Cache.ok?() do
      conn
    else
      conn
      |> not_found_response()
      |> halt()
    end
  end

  def show(conn, %{"id" => screen_id, "last_refresh" => _last_refresh, "datetime" => datetime}) do
    if nonexistent_screen?(screen_id) do
      not_found_response(conn)
    else
      data = Screens.ScreenData.by_screen_id_with_datetime(screen_id, datetime)

      json(conn, data)
    end
  end

  def show(conn, %{"id" => screen_id, "last_refresh" => last_refresh} = params) do
    is_screen = ScreensWeb.UserAgent.screen_conn?(conn, screen_id)

    _ =
      Screens.LogScreenData.log_data_request(
        screen_id,
        last_refresh,
        is_screen,
        params
      )

    if nonexistent_screen?(screen_id) do
      Screens.LogScreenData.log_api_response(:nonexistent, screen_id, last_refresh, is_screen)

      not_found_response(conn)
    else
      data =
        Screens.ScreenData.by_screen_id(screen_id, is_screen,
          check_disabled: true,
          last_refresh: last_refresh
        )

      json(conn, data)
    end
  end

  defp nonexistent_screen?(screen_id) do
    is_nil(Cache.screen(screen_id))
  end

  defp not_found_response(conn) do
    conn
    |> put_status(:not_found)
    |> text("Not found")
  end
end
