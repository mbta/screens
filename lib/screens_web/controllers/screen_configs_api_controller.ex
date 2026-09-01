defmodule ScreensWeb.ScreenConfigsApiController do
  use ScreensWeb, :controller

  alias Screens.ScreenConfigs

  def index(conn, %{"ids" => ids}) do
    config = ids |> parse_query_param_list() |> ScreenConfigs.list_by_ids()

    json(conn, %{config: config})
  end

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

  defp parse_query_param_list(param) do
    param |> String.split(",") |> Enum.map(&String.trim/1) |> Enum.reject(&(&1 == ""))
  end
end
