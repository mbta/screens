defmodule ScreensWeb.ScreenController do
  use ScreensWeb, :controller
  require Logger

  alias Screens.Config.{Screen, State}

  @default_app_id :bus_eink
  @app_ids ~w[bus_eink gl_eink_single gl_eink_double solari]a
  @app_id_strings Enum.map(@app_ids, &Atom.to_string/1)

  plug(:check_config)
  plug(:api_version)
  plug(:environment_name)
  plug(:body_class)

  defp check_config(conn, _) do
    if not Screens.Config.State.ok?() do
      conn
      |> render_not_found()
      |> halt()
    else
      conn
    end
  end

  defp api_version(conn, _) do
    {:ok, api_version} = Screens.Config.State.api_version()
    assign(conn, :api_version, api_version)
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
    {:ok, screens} = State.screens()

    screen_ids =
      for {screen_id, %Screen{app_id: app_id}} <- screens, app_id == target_app_id do
        screen_id
      end

    Enum.sort(screen_ids)
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

    with {screen_id, ""} <- Integer.parse(screen_id),
         {:ok, %Screen{app_id: app_id}} <- State.screen(screen_id) do
      conn
      |> assign(:app_id, app_id)
      |> render("index.html")
    else
      _ -> render_not_found(conn)
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
