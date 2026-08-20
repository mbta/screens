defmodule ScreensWeb.ScreenConfigsApiController do
  use ScreensWeb, :controller

  alias Screens.ScreenConfigs

  def index(conn, _params) do
    json(conn, %{config: ScreenConfigs.list_all()})
  end

  def update(conn, %{"screen_configs" => screen_configs}) when is_list(screen_configs) do
    case ScreenConfigs.commit_updates(screen_configs) do
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
