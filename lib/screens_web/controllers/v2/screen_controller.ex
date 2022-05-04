defmodule ScreensWeb.V2.ScreenController do
  use ScreensWeb, :controller
  require Logger
  alias Screens.Config.{Screen, State}
  alias Screens.V2.ScreenData.Parameters

  @default_app_id :bus_eink
  @recognized_app_ids ~w[bus_eink_v2 bus_shelter_v2 dup_v2 gl_eink_v2 solari_v2 solari_large_v2 pre_fare_v2]a
  @app_id_strings Enum.map(@recognized_app_ids, &Atom.to_string/1)

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

  def index(conn, %{"id" => app_id})
      when app_id in @app_id_strings do
    app_id = String.to_existing_atom(app_id)
    refresh_rate = Parameters.get_refresh_rate(app_id)

    conn
    |> assign(:app_id, app_id)
    |> assign(:refresh_rate, refresh_rate)
    |> assign(:screen_ids_with_offset_map, screen_ids(app_id, refresh_rate))
    |> render("index_multi.html")
  end

  def index(conn, %{"id" => screen_id} = params) do
    is_screen = ScreensWeb.UserAgent.is_screen_conn?(conn, screen_id)

    _ = Screens.LogScreenData.log_page_load(screen_id, is_screen, params["screen_side"])

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
          calculate_refresh_rate_offset(screen_id, refresh_rate)
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

  defp calculate_refresh_rate_offset(screen_id, refresh_rate) do
    screen_id
    |> Base.encode16()
    |> String.to_integer(16)
    |> rem(refresh_rate)
  end

  defp screen_ids(target_app_id, refresh_rate) do
    ids =
      for {screen_id, %Screen{app_id: ^target_app_id}} <- State.screens() do
        screen_id
      end

    Enum.sort(ids, &id_sort_fn/2)
    |> Enum.map(fn id ->
      %{id: id, refresh_rate_offset: calculate_refresh_rate_offset(id, refresh_rate)}
    end)
  end

  defp id_sort_fn(a, b) do
    case {Integer.parse(a), Integer.parse(b)} do
      {{m, ""}, {n, ""}} ->
        m <= n

      _ ->
        a <= b
    end
  end
end
