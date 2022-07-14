defmodule ScreensWeb.V2.ScreenApiController do
  use ScreensWeb, :controller

  alias Screens.Config.State
  alias Screens.V2.ScreenData

  plug(:check_config)

  defp check_config(conn, _) do
    if State.ok?() do
      conn
    else
      conn
      |> not_found_response()
      |> halt()
    end
  end

  def show(conn, %{"id" => screen_id, "last_refresh" => last_refresh} = params) do
    is_screen = ScreensWeb.UserAgent.is_screen_conn?(conn, screen_id)
    screen_side = params["screen_side"]

    Screens.LogScreenData.log_data_request(
      screen_id,
      last_refresh,
      is_screen,
      screen_side
    )

    cond do
      nonexistent_screen?(screen_id) ->
        Screens.LogScreenData.log_api_response(
          :nonexistent,
          screen_id,
          last_refresh,
          is_screen,
          screen_side
        )

        not_found_response(conn)

      outdated?(screen_id, last_refresh) ->
        Screens.LogScreenData.log_api_response(
          :outdated,
          screen_id,
          last_refresh,
          is_screen,
          screen_side
        )

        json(conn, ScreenData.outdated_response())

      disabled?(screen_id) ->
        Screens.LogScreenData.log_api_response(
          :disabled,
          screen_id,
          last_refresh,
          is_screen,
          screen_side
        )

        json(conn, ScreenData.disabled_response())

      true ->
        Screens.LogScreenData.log_api_response(
          :success,
          screen_id,
          last_refresh,
          is_screen,
          screen_side
        )

        json(conn, ScreenData.by_screen_id(screen_id))
    end
  end

  def simulation(conn, %{"id" => screen_id, "last_refresh" => last_refresh}) do
    cond do
      nonexistent_screen?(screen_id) ->
        not_found_response(conn)

      outdated?(screen_id, last_refresh) ->
        json(conn, ScreenData.outdated_response())

      disabled?(screen_id) ->
        json(conn, ScreenData.disabled_response())

      true ->
        {full_page, flex_zone} = ScreenData.simulation_by_screen_id(screen_id)
        json(conn, %{full_page: full_page, flex_zone: flex_zone})
    end
  end

  defp nonexistent_screen?(screen_id) do
    is_nil(State.screen(screen_id))
  end

  defp outdated?(screen_id, client_refresh_timestamp) do
    {:ok, client_refresh_time, _} = DateTime.from_iso8601(client_refresh_timestamp)
    refresh_if_loaded_before_time = State.refresh_if_loaded_before(screen_id)

    case refresh_if_loaded_before_time do
      nil -> false
      _ -> DateTime.compare(client_refresh_time, refresh_if_loaded_before_time) == :lt
    end
  end

  defp disabled?(screen_id) do
    State.disabled?(screen_id)
  end

  defp not_found_response(conn) do
    conn
    |> put_status(:not_found)
    |> text("Not found")
  end
end
