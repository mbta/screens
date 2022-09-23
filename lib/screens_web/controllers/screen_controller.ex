defmodule ScreensWeb.ScreenController do
  use ScreensWeb, :controller
  require Logger

  alias Screens.Config.{Screen, State}

  @default_app_id :bus_eink
  @app_ids ~w[bus_eink gl_eink_single gl_eink_double solari dup]a
  @app_id_strings Enum.map(@app_ids, &Atom.to_string/1)

  plug(:body_class)
  plug(:check_config)
  plug(:environment_name)
  plug(:last_refresh)

  defp check_config(conn, _) do
    if State.ok?() do
      conn
    else
      conn
      |> render_not_found()
      |> halt()
    end
  end

  defp last_refresh(conn, _, now \\ DateTime.utc_now()) do
    timestamp = DateTime.to_iso8601(now)
    assign(conn, :last_refresh, timestamp)
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

  defp id_sort_fn(a, b) do
    case {Integer.parse(a), Integer.parse(b)} do
      {{m, ""}, {n, ""}} ->
        m <= n

      _ ->
        a <= b
    end
  end

  defp screen_ids(target_app_id) do
    ids =
      for {screen_id, %Screen{app_id: ^target_app_id}} <- State.screens() do
        screen_id
      end

    Enum.sort(ids, &id_sort_fn/2)
  end

  def index(conn, %{"id" => app_id})
      when app_id in @app_id_strings do
    app_id = String.to_existing_atom(app_id)

    conn
    |> assign(:app_id, app_id)
    |> assign(:screen_ids, screen_ids(app_id))
    |> render("index_multi.html")
  end

  def index(conn, %{"id" => screen_id} = params) do
    is_screen = ScreensWeb.UserAgent.is_screen_conn?(conn, screen_id)

    _ = Screens.LogScreenData.log_page_load(screen_id, is_screen)

    case State.screen(screen_id) do
      %Screen{app_id: app_id} ->
        conn
        |> assign(:app_id, app_id)
        |> assign(:sentry_frontend_dsn, Application.get_env(:screens, :sentry_frontend_dsn))
        |> assign(:is_real_screen, match?(%{"is_real_screen" => "true"}, params))
        |> assign(:source, params["source"])
        |> render("index.html")

      nil ->
        render_not_found(conn)
    end
  end

  def index(conn, _params) do
    render_not_found(conn)
  end

  def show_image(conn, %{"filename" => filename}) do
    redirect(conn, external: Screens.Image.get_s3_url(filename))
  end

  defp render_not_found(conn) do
    conn
    |> assign(:app_id, @default_app_id)
    |> put_status(:not_found)
    |> put_view(ScreensWeb.ErrorView)
    |> render("404.html")
  end
end
