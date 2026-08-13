defmodule ScreensWeb.ScreenConfigsApiController do
  use ScreensWeb, :controller

  alias Screens.ScreenConfigs

  def index(conn, _params) do
    screen_configs = ScreenConfigs.list_screen_configs()

    json(conn, %{screen_configs: screen_configs})
  end

  def update(conn, %{"screen_configs" => screen_configs} = params) when is_list(screen_configs) do
    deleted_screen_ids = Map.get(params, "deleted_screen_ids", [])

    case ScreenConfigs.commit_updates(screen_configs, deleted_screen_ids) do
      :ok ->
        json(conn, %{success: true})

      {:error, reason} ->
        conn
        |> put_status(500)
        |> json(%{success: false, error: inspect(reason)})
    end
  end

  def update(conn, _params) do
    conn
    |> put_status(400)
    |> json(%{success: false, error: "screen_configs parameter is required"})
  end
end
