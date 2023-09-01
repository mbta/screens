defmodule ScreensWeb.V2.ScreenApiController do
  use ScreensWeb, :controller

  alias Screens.Config.State
  alias Screens.LogScreenData
  alias Screens.Util
  alias Screens.V2.ScreenData

  plug(:check_config)
  plug Corsica, [origins: "*"] when action in [:show_dup, :show_triptych]

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
    rotation_index = params["rotation_index"]
    triptych_pane = params["pane"]
    ofm_app_package_version = params["version"]

    LogScreenData.log_data_request(
      screen_id,
      last_refresh,
      is_screen,
      params["requestor"],
      screen_side,
      rotation_index,
      triptych_pane,
      ofm_app_package_version
    )

    cond do
      nonexistent_screen?(screen_id) ->
        LogScreenData.log_api_response(
          :nonexistent,
          screen_id,
          last_refresh,
          is_screen,
          screen_side
        )

        not_found_response(conn)

      Util.outdated?(screen_id, last_refresh) ->
        LogScreenData.log_api_response(
          :outdated,
          screen_id,
          last_refresh,
          is_screen,
          screen_side
        )

        json(conn, ScreenData.outdated_response())

      disabled?(screen_id) ->
        LogScreenData.log_api_response(
          :disabled,
          screen_id,
          last_refresh,
          is_screen,
          screen_side
        )

        json(conn, ScreenData.disabled_response())

      true ->
        LogScreenData.log_api_response(
          :success,
          screen_id,
          last_refresh,
          is_screen,
          screen_side
        )

        json(conn, ScreenData.by_screen_id(screen_id))
    end
  end

  def show_dup(conn, params), do: show(conn, params)

  def show_triptych(conn, %{"player_name" => player_name} = params) do
    case Screens.TriptychPlayer.fetch_screen_id_for_player(player_name) do
      {:ok, screen_id} ->
        show(conn, Map.put(params, "id", screen_id))

      :error ->
        LogScreenData.log_unrecognized_triptych_player(player_name)

        # Reuse the logic + logging in show/2 for nonexistent IDs.
        # This will log a data request for the nonexistent player name and
        # return a 404 response.
        show(conn, Map.put(params, "id", "triptych_player_name--#{player_name}"))
    end
  end

  def simulation(conn, %{"id" => screen_id, "last_refresh" => last_refresh} = params) do
    LogScreenData.log_data_request(
      screen_id,
      last_refresh,
      false,
      params["requestor"],
      params["screen_side"]
    )

    cond do
      nonexistent_screen?(screen_id) ->
        not_found_response(conn)

      Util.outdated?(screen_id, last_refresh) ->
        json(conn, ScreenData.outdated_response())

      disabled?(screen_id) ->
        json(conn, ScreenData.disabled_response())

      true ->
        json(conn, ScreenData.simulation_data_by_screen_id(screen_id))
    end
  end

  def log_frontend_error(conn, %{
        "id" => screen_id,
        "errorMessage" => error_message,
        "stacktrace" => stack_trace
      }) do
    LogScreenData.log_frontend_error(screen_id, error_message, stack_trace)
    json(conn, %{success: true})
  end

  defp nonexistent_screen?(screen_id) do
    is_nil(State.screen(screen_id))
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
