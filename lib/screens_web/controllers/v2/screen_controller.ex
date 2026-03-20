defmodule ScreensWeb.V2.ScreenController do
  use ScreensWeb, :controller

  alias Screens.Config.Cache
  alias Screens.Report
  alias Screens.V2.ScreenData.Parameters
  alias ScreensConfig.Screen
  alias ScreensWeb.Plug

  plug Plug.LegacyLogging, :page when action == :index
  plug Plug.ScreenRequest when action == :index
  plug Plug.ScreenRequest, :pending when action == :index_pending
  plug :environment_name
  plug :last_refresh

  defp environment_name(conn, _) do
    environment_name = Application.get_env(:screens, :environment_name)
    assign(conn, :environment_name, environment_name)
  end

  defp last_refresh(conn, _) do
    # credo:disable-for-next-line Screens.Checks.UntestableDateTime
    now = DateTime.utc_now() |> DateTime.to_iso8601()
    assign(conn, :last_refresh, now)
  end

  def index(conn, params) do
    conn |> page_assigns(params) |> render("index.html")
  end

  def index_pending(conn, params) do
    conn
    |> page_assigns(params, _pending? = true)
    |> put_view(ScreensWeb.V2.ScreenView)
    |> render("index.html")
  end

  def index_multi(%{assigns: %{app_id: app_id}} = conn, _params) do
    refresh_rate = Parameters.refresh_rate(app_id)

    conn
    |> assign(:app_id, strip_v2(app_id))
    |> assign(:refresh_rate, refresh_rate)
    |> assign(:screen_ids_with_offset_map, screen_ids(app_id, refresh_rate))
    |> render("index_multi.html")
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
  def widget(conn, %{"app_id" => app_id, "widget" => widget_data}) do
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

  defp page_assigns(
         %{assigns: %{screen_id: screen_id, screen: %Screen{app_id: app_id} = screen}} = conn,
         params,
         pending? \\ false
       ) do
    refresh_rate = Parameters.refresh_rate(app_id)

    merge_assigns(conn,
      app_id: strip_v2(app_id),
      refresh_rate: if(pending?, do: 0, else: refresh_rate),
      audio_readout_interval: Parameters.audio_interval_minutes(screen),
      audio_interval_offset_seconds: Parameters.audio_interval_offset_seconds(screen),
      sentry_dsn: if(params["disable_sentry"], do: nil, else: Sentry.get_dsn()),
      refresh_rate_offset: calculate_refresh_rate_offset(screen_id, refresh_rate),
      is_pending: pending?
    )
  end

  defp calculate_refresh_rate_offset(screen_id, refresh_rate) do
    screen_id
    |> Base.encode16()
    |> String.to_integer(16)
    |> rem(refresh_rate)
  end

  defp screen_ids(target_app_id, refresh_rate) do
    Cache.screen_ids(&match?({_screen_id, %Screen{app_id: ^target_app_id}}, &1))
    |> Enum.map(&%{id: &1, refresh_rate_offset: calculate_refresh_rate_offset(&1, refresh_rate)})
  end

  # While app IDs in configuration still have the "_v2" suffix, but this suffix has been removed
  # from JS/CSS entrypoints, we temporarily need to translate from one to the other.
  defp strip_v2(app_id), do: app_id |> to_string() |> String.replace("_v2", "")
end
