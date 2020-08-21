defmodule ScreensWeb.ScreenController do
  use ScreensWeb, :controller
  require Logger

  alias Screens.Config.{Screen, State}

  @default_app_id :bus_eink
  @app_ids ~w[bus_eink gl_eink_single gl_eink_double solari]a
  @app_id_strings Enum.map(@app_ids, &Atom.to_string/1)

  plug(:check_config)
  plug(:environment_name)
  plug(:last_refresh)
  plug(:body_class)

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

  defp body_class(conn, _) do
    body_class =
      case Map.get(conn.params, "scroll") do
        "true" -> "scroll-enabled"
        _ -> "scroll-disabled"
      end

    assign(conn, :body_class, body_class)
  end

  defp screen_ids(target_app_id) do
    screen_ids =
      for {screen_id, %Screen{app_id: app_id}} <- State.screens(), app_id == target_app_id do
        screen_id
      end

    Enum.sort_by(screen_ids, &String.to_integer/1)
  end

  def index(conn, %{"id" => app_id})
      when app_id in @app_id_strings do
    app_id = String.to_existing_atom(app_id)

    conn
    |> assign(:app_id, app_id)
    |> assign(:screen_ids, screen_ids(app_id))
    |> render("index_multi.html")
  end

  def index(conn, %{"id" => screen_id}) do
    is_screen = ScreensWeb.UserAgent.is_screen_conn?(conn)

    _ = Screens.LogScreenData.log_page_load(screen_id, is_screen)

    case State.screen(screen_id) do
      %Screen{app_id: app_id} ->
        conn
        |> assign(:app_id, app_id)
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
