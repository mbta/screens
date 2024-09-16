defmodule ScreensWeb.V2.ScreenApiController do
  use ScreensWeb, :controller

  alias Phoenix.View
  alias Screens.Config.Cache
  alias Screens.LogScreenData
  alias Screens.Util
  alias Screens.V2.{ScreenAudioData, ScreenData}
  alias ScreensConfig.Screen

  @base_response %{data: nil, disabled: false, force_reload: false}
  @disabled_response %{@base_response | disabled: true}
  @outdated_response %{@base_response | force_reload: true}

  plug(:check_config)

  plug Corsica, [origins: "*"] when action in [:show_dup, :log_frontend_error]

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
    is_screen = ScreensWeb.UserAgent.screen_conn?(conn, screen_id)
    screen_side = params["screen_side"]
    variant = params["variant"]
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

        json(conn, @outdated_response)

      disabled?(screen_id) ->
        LogScreenData.log_api_response(
          :disabled,
          screen_id,
          last_refresh,
          is_screen,
          screen_side
        )

        json(conn, @disabled_response)

      true ->
        LogScreenData.log_api_response(
          :success,
          screen_id,
          last_refresh,
          is_screen,
          screen_side
        )

        response =
          screen_id
          |> screen_response(variant,
            run_all_variants?: true,
            update_visible_alerts?: true
          )
          |> put_extra_fields(screen_id, screen)

        json(conn, response)
    end
  end

  defp screen_response(screen_id, "all", opts) do
    {default, variants} = ScreenData.variants(screen_id, opts)
    Map.put(%{@base_response | data: default}, :variants, variants)
  end

  defp screen_response(screen_id, variant, opts) do
    data = ScreenData.get(screen_id, Keyword.put(opts, :generator_variant, variant))
    %{@base_response | data: data}
  end

  # Add extra fields used by the Mercury E-ink client
  defp put_extra_fields(response, screen_id, %Screen{app_id: :gl_eink_v2}) do
    response
    # Used to enable audio readout without additional network requests
    # https://app.asana.com/0/1176097567827729/1205748798471858/f
    |> Map.put(:audio_data, fetch_ssml(screen_id))
    # Used to help optimize data refreshes
    # https://app.asana.com/0/1185117109217413/1205234924224431/f
    |> Map.put(:last_deploy_timestamp, Cache.last_deploy_timestamp())
  end

  defp put_extra_fields(response, _, _), do: response

  defp fetch_ssml(screen_id) do
    case ScreenAudioData.by_screen_id(screen_id) do
      [] ->
        ""

      data ->
        View.render_to_string(ScreensWeb.V2.AudioView, "index.ssml", widget_audio_data: data)
    end
  end

  def show_dup(conn, params), do: show(conn, params)

  def simulation(conn, %{"id" => screen_id, "last_refresh" => last_refresh} = params) do
    variant = params["variant"]

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
        json(conn, @outdated_response)

      disabled?(screen_id) ->
        json(conn, @disabled_response)

      true ->
        json(conn, simulation_response(screen_id, variant))
    end
  end

  defp simulation_response(screen_id, "all") do
    {default, variants} = ScreenData.simulation_variants(screen_id)
    Map.put(%{@base_response | data: default}, :variants, variants)
  end

  defp simulation_response(screen_id, variant) do
    %{@base_response | data: ScreenData.simulation(screen_id, generator_variant: variant)}
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
          ScreenData.get(
            screen_id,
            pending_config: config
          )

        json(conn, %{@base_response | data: screen_data})
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
      nil ->
        not_found_response(conn)

      config ->
        screen_data = ScreenData.simulation(screen_id, pending_config: config)
        json(conn, %{@base_response | data: screen_data})
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
      config = ScreensConfig.PendingConfig.from_json(raw_map)
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
