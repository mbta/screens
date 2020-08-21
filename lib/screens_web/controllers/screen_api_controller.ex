defmodule ScreensWeb.ScreenApiController do
  use ScreensWeb, :controller
  require Logger
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

  def show(conn, %{"id" => screen_id, "last_refresh" => _last_refresh, "datetime" => datetime}) do
    data = Screens.ScreenData.by_screen_id_with_datetime(screen_id, datetime)

    json(conn, data)
  end

  def show(conn, %{"id" => screen_id, "last_refresh" => last_refresh}) do
    is_screen = ScreensWeb.UserAgent.is_screen_conn?(conn)

    _ = Screens.LogScreenData.log_data_request(screen_id, last_refresh, is_screen)

    data =
      Screens.ScreenData.by_screen_id(screen_id, is_screen,
        check_disabled: true,
        last_refresh: last_refresh
      )

    json(conn, data)
  end

  # Older clients use version to determine whether they're outdated. We want these
  # clients to reload, so we have to (temporarily) handle these requests.
  def show(conn, %{"version" => _version}) do
    data = %{force_reload: true}
    json(conn, data)
  end
end
