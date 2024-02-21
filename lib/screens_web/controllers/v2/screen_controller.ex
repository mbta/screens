defmodule ScreensWeb.V2.ScreenController do
  use ScreensWeb, :controller
  require Logger
  alias Screens.Config.Cache
  alias Screens.V2.ScreenData.Parameters
  alias ScreensConfig.Screen

  @default_app_id :bus_eink
  @recognized_app_ids ~w[bus_eink_v2 bus_shelter_v2 dup_v2 gl_eink_v2 solari_v2 solari_large_v2 pre_fare_v2 triptych_v2]a
  @app_id_strings Enum.map(@recognized_app_ids, &Atom.to_string/1)

  plug(:check_config)
  plug(:environment_name)
  plug(:last_refresh)
  plug(:v2_layout)

  defp check_config(conn, _) do
    if Cache.ok?() do
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

  defp v2_layout(conn, _) do
    put_layout(conn, {ScreensWeb.V2.LayoutView, "app.html"})
  end

  defp screen_side(params) do
    case params["screen_side"] do
      "left" -> "left"
      "right" -> "right"
      _ -> nil
    end
  end

  defp rotation_index(params) do
    case params["rotation_index"] do
      "0" -> "0"
      "1" -> "1"
      "2" -> "2"
      _ -> nil
    end
  end

  defp triptych_pane(params) do
    case params["pane"] do
      "left" -> "left"
      "middle" -> "middle"
      "right" -> "right"
      _ -> nil
    end
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

    _ = Screens.LogScreenData.log_page_load(screen_id, is_screen, screen_side(params))

    config = Cache.screen(screen_id)

    if is_struct(config, Screen) do
      assigns = get_assigns(params, screen_id, config)

      conn
      |> merge_assigns(assigns)
      |> put_view(ScreensWeb.V2.ScreenView)
      |> render("index.html")
    else
      render_not_found(conn)
    end
  end

  def index(conn, _params) do
    render_not_found(conn)
  end

  def index_pending(conn, %{"id" => screen_id} = params) do
    config =
      with {:ok, config_json} <- Screens.PendingConfig.Fetch.fetch_config(),
           {:ok, raw_map} <- Jason.decode(config_json) do
        pending_config = ScreensConfig.PendingConfig.from_json(raw_map)
        pending_config.screens[screen_id]
      else
        _ -> nil
      end

    if config != nil do
      # Pending screen pages work exactly the same as normal screen pages,
      # except they don't do data refreshes.
      assigns =
        params
        |> get_assigns(screen_id, config)
        |> Keyword.replace(:refresh_rate, 0)
        |> Keyword.put(:is_pending, true)

      conn
      |> merge_assigns(assigns)
      |> put_view(ScreensWeb.V2.ScreenView)
      |> render("index.html")
    else
      render_not_found(conn)
    end
  end

  def index_pending(conn, _params) do
    render_not_found(conn)
  end

  defp get_assigns(params, screen_id, %Screen{app_id: app_id} = config) do
    refresh_rate = Parameters.get_refresh_rate(app_id)

    [
      app_id: app_id,
      refresh_rate: refresh_rate,
      audio_readout_interval: Parameters.get_audio_readout_interval(app_id),
      audio_interval_offset_seconds: Parameters.get_audio_interval_offset_seconds(config),
      sentry_frontend_dsn: Application.get_env(:screens, :sentry_frontend_dsn),
      refresh_rate_offset: calculate_refresh_rate_offset(screen_id, refresh_rate),
      is_real_screen: match?(%{"is_real_screen" => "true"}, params),
      screen_side: screen_side(params),
      requestor: params["requestor"],
      disable_sentry: params["disable_sentry"],
      rotation_index: rotation_index(params),
      triptych_pane: triptych_pane(params),
      is_pending: false
    ]
  end

  # Handles widget page GET requests with widget data as a query param.
  # Phoenix does not automatically decode JSON received in query params.
  def widget(conn, %{"app_id" => app_id, "widget" => json_data}) when is_binary(json_data) do
    case Jason.decode(json_data) do
      {:ok, widget_data} ->
        widget(conn, %{"app_id" => app_id, "widget" => widget_data})

      {:error, _} ->
        conn
        |> put_status(:bad_request)
        |> text(
          "GET /v2/widget/#{app_id} request must contain a `widget` query param containing JSON"
        )
    end
  end

  # Handles widget page POST requests with widget data as a JSON request body.
  # Phoenix automatically decodes JSON received in POST body.
  def widget(conn, %{"app_id" => app_id, "widget" => widget_data})
      when app_id in @app_id_strings do
    app_id = String.to_existing_atom(app_id)

    conn
    |> assign(:app_id, app_id)
    |> assign(:widget_data, Jason.encode!(widget_data))
    |> render("index_widget.html")
  end

  def widget(conn, %{"app_id" => app_id}) do
    app_id = String.to_existing_atom(app_id)

    conn
    |> put_status(:bad_request)
    |> text("POST /v2/widget/#{app_id} request must contain a JSON body with `widget` key")
  end

  def simulation(conn, params) do
    conn
    |> assign(
      :screenplay_fullstory_org_id,
      Application.get_env(:screens, :screenplay_fullstory_org_id)
    )
    |> index(params)
  end

  def simulation_pending(conn, params) do
    conn
    |> assign(
      :screenplay_fullstory_org_id,
      Application.get_env(:screens, :screenplay_fullstory_org_id)
    )
    |> index_pending(params)
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
    ids = Cache.screen_ids(&match?({_screen_id, %Screen{app_id: ^target_app_id}}, &1))

    ids
    |> Enum.sort(&id_sort_fn/2)
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
