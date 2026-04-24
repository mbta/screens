defmodule ScreensWeb.V2.ScreenApiController do
  use ScreensWeb, :controller

  alias Phoenix.View
  alias Screens.Config.Cache
  alias Screens.V2.{ScreenAudioData, ScreenData}
  alias ScreensConfig.Screen
  alias ScreensWeb.Plug.{LegacyLogging, ScreenRequest, VariantCanary}

  @base_response %{data: nil, disabled: false, force_reload: false}

  @non_pending_show_actions [:show, :show_dup, :simulation]
  @pending_show_actions [:show_pending, :simulation_pending]

  plug Corsica, [origins: "*"] when action in [:show_dup, :log_frontend_error]
  plug ScreenRequest, [type: :data] when action in @non_pending_show_actions
  plug ScreenRequest, [type: :data, pending?: true] when action in @pending_show_actions
  plug LegacyLogging, :data when action in [:show, :show_dup]
  plug VariantCanary when action in @non_pending_show_actions
  plug :disabled_response when action in @non_pending_show_actions
  plug :outdated_response when action in @non_pending_show_actions

  def show(%{assigns: %{screen_id: screen_id, screen: screen, variant: variant}} = conn, _params) do
    response =
      screen
      |> screen_response(variant, update_visible_alerts_for_screen_id: screen_id)
      |> put_extra_fields(screen)

    json(conn, response)
  end

  def show_dup(conn, params), do: show(conn, params)

  def simulation(%{assigns: %{screen: screen, variant: variant}} = conn, _params) do
    json(conn, simulation_response(screen, variant))
  end

  def show_pending(%{assigns: %{screen: screen}} = conn, _params) do
    json(conn, %{@base_response | data: ScreenData.get(screen)})
  end

  def simulation_pending(%{assigns: %{screen: screen}} = conn, _params) do
    json(conn, %{@base_response | data: ScreenData.simulation(screen)})
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

    Logster.warning([
      "[screen frontend error]",
      screen_id: id,
      error_message: inspect(error_message),
      stack_trace: inspect(stacktrace)
    ])

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

  defp screen_response(screen, "all", _opts) do
    {default, variants} = ScreenData.variants(screen)
    Map.put(%{@base_response | data: default}, :variants, variants)
  end

  # See `docs/mercury_api.md`
  defp screen_response(%Screen{vendor: :mercury} = screen, variant, opts) do
    %{full_page: data, flex_zone: flex_zone} =
      ScreenData.simulation(screen, merge_options(variant, opts))

    Map.merge(%{@base_response | data: data}, %{flex_zone: flex_zone})
  end

  defp screen_response(screen, variant, opts) do
    data = ScreenData.get(screen, merge_options(variant, opts))
    %{@base_response | data: data}
  end

  defp merge_options(variant, opts) do
    Keyword.put(opts, :generator_variant, variant)
  end

  # See `docs/mercury_api.md`
  defp put_extra_fields(response, %Screen{vendor: :mercury} = screen) do
    response
    |> Map.put(:audio_data, fetch_ssml(screen))
    |> Map.put(:last_deploy_timestamp, Cache.last_deploy_timestamp())
  end

  defp put_extra_fields(response, _screen), do: response

  defp fetch_ssml(screen) do
    case ScreenAudioData.get(screen) do
      [] ->
        ""

      data ->
        View.render_to_string(ScreensWeb.V2.AudioView, "index.ssml", widget_audio_data: data)
    end
  end

  defp simulation_response(screen, "all") do
    {default, variants} = ScreenData.simulation_variants(screen)
    Map.put(%{@base_response | data: default}, :variants, variants)
  end

  defp simulation_response(screen, variant) do
    %{@base_response | data: ScreenData.simulation(screen, generator_variant: variant)}
  end

  defp disabled_response(%{assigns: %{screen: %Screen{disabled: true}}} = conn, _) do
    Logger.metadata(response_type: :disabled)
    conn |> json(%{@base_response | disabled: true}) |> halt()
  end

  defp disabled_response(conn, _), do: conn

  # Never tell a DUP client to reload, since it would just reload its local copy of the client
  # code, not changing anything, resulting in an infinite loop. TODO: Rework this once we support
  # non-Outfront-managed DUPs (should not rely on IDs having a specific format).
  defp outdated_response(%{assigns: %{screen_id: "DUP-" <> _}} = conn, _), do: conn

  defp outdated_response(
         %{
           assigns: %{screen: %Screen{refresh_if_loaded_before: refresh_if_loaded_before}},
           params: params
         } = conn,
         _
       ) do
    with param when is_binary(param) <- params["last_refresh"],
         {:ok, last_refresh_at, _offset} <- DateTime.from_iso8601(param) do
      should_refresh_at =
        [Cache.last_deploy_timestamp(), refresh_if_loaded_before]
        |> Enum.reject(&is_nil/1)
        |> Enum.max(DateTime, fn -> nil end)

      if not is_nil(should_refresh_at) and
           DateTime.compare(last_refresh_at, should_refresh_at) == :lt do
        Logger.metadata(response_type: :outdated)
        conn |> json(%{@base_response | force_reload: true}) |> halt()
      else
        conn
      end
    else
      _ ->
        conn
        |> put_status(400)
        |> text("last_refresh parameter missing or not a valid ISO8601 datetime")
        |> halt()
    end
  end
end
