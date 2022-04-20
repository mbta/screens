defmodule ScreensWeb.V2.ScreenController do
  use ScreensWeb, :controller
  require Logger
  alias Screens.Config.{Screen, State}
  alias Screens.V2.ScreenData.Parameters

  @default_app_id :bus_eink

  plug(:check_config)
  plug(:environment_name)
  plug(:last_refresh)
  plug(:v2_layout)

  defp check_config(conn, _) do
    if State.ok?() do
      conn
    else
      conn
      |> render_not_found()
      |> halt()
    end
  end

  defp last_refresh(conn, _) do
    now = DateTime.utc_now() |> DateTime.to_iso8601()
    assign(conn, :last_refresh, now)
  end

  defp environment_name(conn, _) do
    environment_name = Application.get_env(:screens, :environment_name)
    assign(conn, :environment_name, environment_name)
  end

  defp v2_layout(conn, _) do
    put_layout(conn, {ScreensWeb.V2.LayoutView, "app.html"})
  end

  def index(conn, %{"id" => screen_id} = params) do
    is_screen = ScreensWeb.UserAgent.is_screen_conn?(conn, screen_id)
    screen_side = get_screen_side(params)

    _ = Screens.LogScreenData.log_page_load(screen_id, is_screen, screen_side)

    config = State.screen(screen_id)

    case config do
      %Screen{app_id: app_id} ->
        refresh_rate = Parameters.get_refresh_rate(app_id)

        conn
        |> assign(:app_id, app_id)
        |> assign(:refresh_rate, refresh_rate)
        |> assign(:audio_readout_interval, Parameters.get_audio_readout_interval(app_id))
        |> assign(
          :audio_interval_offset_seconds,
          Parameters.get_audio_interval_offset_seconds(config)
        )
        |> assign(:sentry_frontend_dsn, Application.get_env(:screens, :sentry_frontend_dsn))
        |> assign(
          :refresh_rate_offset,
          screen_id
          |> Base.encode16()
          |> String.to_integer(16)
          |> rem(refresh_rate)
        )
        |> put_view(ScreensWeb.V2.ScreenView)
        |> render("index.html")

      nil ->
        render_not_found(conn)
    end
  end

  def index(conn, _params) do
    render_not_found(conn)
  end

  defp render_not_found(conn) do
    conn
    |> assign(:app_id, @default_app_id)
    |> put_status(:not_found)
    |> put_view(ScreensWeb.ErrorView)
    |> render("404.html")
  end

  defp get_screen_side(%{"screen_side" => screen_side}), do: screen_side
  defp get_screen_side(_), do: nil
end
