defmodule ScreensWeb.ScreenApiController do
  use ScreensWeb, :controller
  require Logger

  plug(:check_config)

  defp check_config(conn, _) do
    if Screens.Config.State.ok?() do
      conn
    else
      conn
      |> put_status(:not_found)
      |> halt()
    end
  end

  def show(conn, %{"id" => screen_id, "version" => _version, "datetime" => datetime}) do
    {screen_id, ""} = Integer.parse(screen_id)

    data = Screens.ScreenData.by_screen_id_with_datetime(screen_id, datetime)

    json(conn, data)
  end

  def show(conn, %{"id" => screen_id, "version" => version}) do
    {screen_id, ""} = Integer.parse(screen_id)

    is_screen = ScreensWeb.UserAgent.is_screen_conn?(conn)

    _ = Screens.LogScreenData.log_data_request(screen_id, version, is_screen)

    data =
      Screens.ScreenData.by_screen_id(screen_id, is_screen,
        check_disabled: true,
        client_version: version
      )

    json(conn, data)
  end
end
