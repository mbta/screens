defmodule ScreensWeb.ScreenController do
  use ScreensWeb, :controller
  require Logger

  @default_app_id "bus_eink"
  @app_ids ["bus_eink", "gl_eink_single", "gl_eink_double"]

  plug(:api_version)
  plug(:environment_name)

  defp api_version(conn, _) do
    api_version = Application.get_env(:screens, :api_version)
    assign(conn, :api_version, api_version)
  end

  defp environment_name(conn, _) do
    environment_name = Application.get_env(:screens, :environment_name)
    assign(conn, :environment_name, environment_name)
  end

  defp screen_ids(target_app_id) do
    :screens
    |> Application.get_env(:screen_data)
    |> Enum.reduce([], fn {screen_id, %{app_id: app_id}}, acc ->
      if app_id == target_app_id do
        [String.to_integer(screen_id) | acc]
      else
        acc
      end
    end)
    |> Enum.sort()
  end

  def index(conn, %{"id" => app_id})
      when app_id in @app_ids do
    conn
    |> assign(:app_id, app_id)
    |> assign(:screen_ids, screen_ids(app_id))
    |> render("index_multi.html")
  end

  def index(conn, %{"id" => screen_id}) do
    screen_data =
      :screens
      |> Application.get_env(:screen_data)
      |> Map.get(screen_id)

    is_screen = ScreensWeb.UserAgent.is_screen_conn?(conn)

    _ =
      if is_screen do
        Logger.info("[screen page load] screen_id=#{screen_id}")
      end

    case screen_data do
      nil ->
        render_not_found(conn)

      %{app_id: app_id} ->
        conn
        |> assign(:app_id, app_id)
        |> render("index.html")
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
