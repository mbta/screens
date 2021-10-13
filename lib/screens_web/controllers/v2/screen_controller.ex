defmodule ScreensWeb.V2.ScreenController do
  use ScreensWeb, :controller

  require Logger

  alias Screens.Config.{Screen, State}
  alias Screens.Config.V2.{Audio, BusShelter}
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

  defp assign_volume(conn, config) do
    case config do
      %Screen{app_params: %BusShelter{audio: %Audio{volume: volume}}} ->
        assign(conn, :volume, volume)

      %Screen{} ->
        assign(conn, :volume, 0.0)
    end
  end

  def index(conn, %{"id" => screen_id}) do
    is_screen = ScreensWeb.UserAgent.is_screen_conn?(conn, screen_id)

    _ = Screens.LogScreenData.log_page_load(screen_id, is_screen)

    config = State.screen(screen_id)

    case config do
      %Screen{app_id: app_id} ->
        _ =
          if app_id == :bus_shelter_v2 do
            Logger.info("[bus shelter screen request] screen_id=#{screen_id}")
          end

        conn
        |> assign(:app_id, app_id)
        |> assign(:refresh_rate, Parameters.get_refresh_rate(app_id))
        |> assign_volume(config)
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
end
