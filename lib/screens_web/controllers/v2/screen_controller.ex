defmodule ScreensWeb.V2.ScreenController do
  use ScreensWeb, :controller

  alias Screens.Config.Cache
  alias Screens.Report
  alias Screens.V2.ScreenData.Parameters
  alias ScreensConfig.Screen
  alias ScreensConfig.Screen.PreFare

  @recognized_app_ids ~w[bus_eink_v2 bus_shelter_v2 busway_v2 dup_v2 elevator_v2 gl_eink_v2 pre_fare_v2]a
  @app_id_strings Enum.map(@recognized_app_ids, &Atom.to_string/1)

  plug(:check_config)
  plug(:environment_name)
  plug(:last_refresh)

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

  defp screen_side(%PreFare{template: :duo}, %{"screen_side" => "left"}), do: "left"
  defp screen_side(%PreFare{template: :duo}, %{"screen_side" => "right"}), do: "right"
  defp screen_side(%PreFare{template: :duo}, _query_params), do: "duo"
  defp screen_side(%PreFare{template: :solo}, _query_params), do: "solo"
  defp screen_side(_app_params, _query_params), do: nil

  defp rotation_index(params) do
    case params["rotation_index"] do
      "0" -> "0"
      "1" -> "1"
      "2" -> "2"
      _ -> nil
    end
  end

  def index(conn, %{"id" => app_id})
      when app_id in @app_id_strings do
    app_id = String.to_existing_atom(app_id)
    refresh_rate = Parameters.refresh_rate(app_id)

    conn
    |> assign(:app_id, strip_v2(app_id))
    |> assign(:refresh_rate, refresh_rate)
    |> assign(:screen_ids_with_offset_map, screen_ids(app_id, refresh_rate))
    |> render("index_multi.html")
  end

  def index(conn, %{"id" => screen_id} = params) do
    _ = Screens.LogScreenData.log_page_load(screen_id, params)
    config = Cache.screen(screen_id)

    if match?(%Screen{app_id: app_id} when app_id in @recognized_app_ids, config) do
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

  defp get_assigns(params, screen_id, %Screen{app_id: app_id, app_params: app_params} = config) do
    refresh_rate = Parameters.refresh_rate(app_id)

    [
      app_id: strip_v2(app_id),
      refresh_rate: refresh_rate,
      audio_readout_interval: Parameters.audio_interval_minutes(config),
      audio_interval_offset_seconds: Parameters.audio_interval_offset_seconds(config),
      sentry_dsn: if(params["disable_sentry"], do: nil, else: Sentry.get_dsn()),
      refresh_rate_offset: calculate_refresh_rate_offset(screen_id, refresh_rate),
      is_real_screen: match?(%{"is_real_screen" => "true"}, params),
      screen_side: screen_side(app_params, params),
      requestor: params["requestor"],
      rotation_index: rotation_index(params),
      variant: params["variant"],
      is_pending: false
    ]
  end

  # Handles widget page GET requests with widget data as a query param.
  def widget(conn, %{"app_id" => app_id, "widget" => json_data}) when is_binary(json_data) do
    # Phoenix does not automatically decode JSON received in query params.
    case Jason.decode(json_data) do
      {:ok, widget_data} ->
        widget(conn, %{"app_id" => app_id, "widget" => widget_data})

      {:error, _} ->
        Report.error("invalid_widget_json", app_id: app_id, source: :query)

        conn
        |> put_status(:bad_request)
        |> text(
          "GET /v2/widget/#{app_id} request must contain a `widget` query param containing JSON"
        )
    end
  end

  # Handles widget page POST requests with widget data as a JSON request body.
  def widget(conn, %{"app_id" => app_id, "widget" => widget_data})
      when app_id in @app_id_strings do
    app_id = String.to_existing_atom(app_id)

    conn
    |> assign(:app_id, strip_v2(app_id))
    |> assign(:widget_data, Jason.encode!(widget_data))
    |> render("index_widget.html")
  end

  def widget(conn, %{"app_id" => app_id}) do
    app_id = String.to_existing_atom(app_id)
    Report.error("invalid_widget_json", app_id: app_id, source: :body)

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
    |> put_status(:not_found)
    |> put_layout(html: :error)
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

  # While app IDs in configuration still have the "_v2" suffix, but this suffix has been removed
  # from JS/CSS entrypoints, we temporarily need to translate from one to the other.
  defp strip_v2(app_id), do: app_id |> to_string() |> String.replace("_v2", "")
end
