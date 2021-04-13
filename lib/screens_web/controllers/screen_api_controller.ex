defmodule ScreensWeb.ScreenApiController do
  use ScreensWeb, :controller
  require Logger
  alias Screens.Config.State

  plug(:check_config)
  plug Corsica, [origins: "*"] when action == :show_dup

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
    _ = log_solari_user_agent(screen_id, conn)

    data =
      Screens.ScreenData.by_screen_id(screen_id, is_screen,
        check_disabled: true,
        last_refresh: last_refresh
      )

    json(conn, data)
  end

  def show_dup(conn, %{"id" => screen_id, "rotation_index" => rotation_index}) do
    is_screen = ScreensWeb.UserAgent.is_screen_conn?(conn)

    _ = Screens.LogScreenData.log_data_request(screen_id, nil, is_screen)

    data = Screens.DupScreenData.by_screen_id(screen_id, rotation_index)

    json(conn, data)
  end

  defp log_solari_user_agent(screen_id, conn) when "300" < screen_id and screen_id < "320" do
    user_agent =
      conn.req_headers
      |> Enum.into(%{})
      |> Map.get("user-agent")

    if !is_nil(user_agent) do
      Logger.info("[user agent] #{user_agent}")
    end
  end

  defp log_solari_user_agent(_screen_id, _conn), do: nil
end
