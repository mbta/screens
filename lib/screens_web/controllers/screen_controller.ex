defmodule ScreensWeb.ScreenController do
  use ScreensWeb, :controller

  plug(:api_version)

  defp api_version(conn, _) do
    api_version = Application.get_env(:screens, :api_version)
    assign(conn, :api_version, api_version)
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
      when app_id in ["bus_eink", "gl_eink_single", "gl_eink_double"] do
    conn
    |> assign(:app_id, app_id)
    |> assign(:screen_ids, screen_ids(app_id))
    |> render("index_multi.html")
  end

  def index(conn, %{"id" => screen_id}) do
    app_id =
      :screens
      |> Application.get_env(:screen_data)
      |> Map.get(screen_id)
      |> Map.get(:app_id)

    conn
    |> assign(:app_id, app_id)
    |> render("index.html")
  end
end
