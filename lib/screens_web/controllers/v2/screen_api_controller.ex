defmodule ScreensWeb.V2.ScreenApiController do
  use ScreensWeb, :controller

  alias Phoenix.View
  alias Screens.Config.Cache
  alias Screens.LogScreenData
  alias Screens.Util
  alias ScreensConfig.Screen
  alias Screens.V2.{ScreenAudioData, ScreenData}

  plug(:check_config)

  plug Corsica, [origins: "*"] when action in [:show_dup, :show_triptych, :log_frontend_error]

  defp check_config(conn, _) do
    if Cache.ok?() do
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
    triptych_pane = params["pane"]
    screen = Cache.screen(screen_id)

    LogScreenData.log_data_request(
      screen_id,
      last_refresh,
      is_screen,
      params
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

        screen_data =
          screen_id
          |> ScreenData.by_screen_id(
            logging_options: %{
              is_real_screen: is_screen,
              screen_id: screen_id,
              triptych_pane: triptych_pane
            }
          )
          |> put_audio_data(screen_id, screen)

        json(conn, screen_data)
    end
  end

  defp put_audio_data(screen_data, screen_id, %Screen{app_id: :gl_eink_v2}) do
    audio_data = fetch_ssml(screen_id) || ""

    Map.put(screen_data, :audio_data, audio_data)
  end

  defp put_audio_data(screen_data, _, _), do: screen_data

  defp fetch_ssml(screen_id) do
    widget_audio_data = ScreenAudioData.by_screen_id(screen_id)

    render_ssml(widget_audio_data: widget_audio_data)
  end

  defp render_ssml(widget_audio_data: []), do: nil

  defp render_ssml(template_assigns) do
    View.render_to_string(ScreensWeb.V2.AudioView, "index.ssml", template_assigns)
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
      params
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

  def show_pending(conn, %{"id" => screen_id, "last_refresh" => last_refresh} = params) do
    LogScreenData.log_data_request(
      screen_id,
      last_refresh,
      false,
      params
    )

    case get_pending_screen_config(screen_id) do
      nil ->
        not_found_response(conn)

      config ->
        screen_data =
          ScreenData.pending_data_by_screen_config(
            config,
            logging_options: %{
              is_real_screen: false,
              screen_id: screen_id,
              triptych_pane: "UNKNOWN"
            }
          )

        json(conn, screen_data)
    end
  end

  def simulation_pending(conn, %{"id" => screen_id, "last_refresh" => last_refresh} = params) do
    LogScreenData.log_data_request(
      screen_id,
      last_refresh,
      false,
      params
    )

    case get_pending_screen_config(screen_id) do
      nil -> not_found_response(conn)
      config -> json(conn, ScreenData.pending_simulation_data_by_screen_config(config))
    end
  end

  def log_frontend_error(conn, params) do
    # Some basic defensive measures since this endpoint is very permissive.
    # We make sure each param is a string and trim them to reasonable lengths, in case they're huge.
    id = params["id"]
    true = is_binary(id)
    id = String.slice(id, 0..99)

    error_message = params["errorMessage"]
    true = is_binary(error_message)
    error_message = String.slice(error_message, 0..499)

    stacktrace = params["stacktrace"]
    true = is_binary(stacktrace)
    stacktrace = String.slice(stacktrace, 0..999)

    LogScreenData.log_frontend_error(id, error_message, stacktrace)
    json(conn, %{success: true})
  end

  def log_frontend_error_preflight(conn, _) do
    # https://developer.mozilla.org/en-US/docs/Glossary/Preflight_request
    # When coming from an OFM client package, the client asks permission
    # to make this cross-origin POST request and we need to tell it that that's ok.
    Corsica.send_preflight_resp(conn,
      origins: "*",
      allow_methods: ["POST"],
      allow_headers: ["content-type"]
    )
  end

  defp get_pending_screen_config(screen_id) do
    with {:ok, config_json} <- Screens.PendingConfig.Fetch.fetch_config(),
         {:ok, raw_map} <- Jason.decode(config_json) do
      config = Screens.PendingConfig.from_json(raw_map)
      config.screens[screen_id]
    else
      _ -> nil
    end
  end

  defp nonexistent_screen?(screen_id) do
    is_nil(Cache.screen(screen_id))
  end

  defp disabled?(screen_id) do
    Cache.disabled?(screen_id)
  end

  defp not_found_response(conn) do
    conn
    |> put_status(:not_found)
    |> text("Not found")
  end
end
