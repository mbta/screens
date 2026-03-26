defmodule ScreensWeb.V2.ScreenApiController do
  use ScreensWeb, :controller

  alias Phoenix.View
  alias Screens.Config.Cache
  alias Screens.Util
  alias Screens.V2.{ScreenAudioData, ScreenData}
  alias ScreensConfig.Screen
  alias ScreensWeb.Plug.{LegacyLogging, ScreenRequest}

  @base_response %{data: nil, disabled: false, force_reload: false}

  plug Corsica, [origins: "*"] when action in [:show_dup, :log_frontend_error]
  plug LegacyLogging, :data when action in [:show, :show_dup]
  plug ScreenRequest when action in [:show, :show_dup, :simulation]
  plug ScreenRequest, :pending when action in [:show_pending, :simulation_pending]
  plug :special_response when action in [:show, :show_dup, :simulation]

  defp special_response(
         %{assigns: %{screen_id: screen_id}, params: %{"last_refresh" => last_refresh}} = conn,
         _
       ) do
    cond do
      Cache.disabled?(screen_id) ->
        Logger.metadata(response_type: :disabled)
        conn |> json(%{@base_response | disabled: true}) |> halt()

      Util.outdated?(screen_id, last_refresh) ->
        Logger.metadata(response_type: :outdated)
        conn |> json(%{@base_response | force_reload: true}) |> halt()

      true ->
        Logger.metadata(response_type: :ok)
        conn
    end
  end

  def show(%{assigns: %{screen_id: screen_id, screen: screen, variant: variant}} = conn, _params) do
    response =
      screen_id
      |> screen_response(screen, variant, update_visible_alerts?: true)
      |> put_extra_fields(screen_id, screen)

    json(conn, response)
  end

  def show_dup(conn, params), do: show(conn, params)

  def simulation(%{assigns: %{screen_id: screen_id, variant: variant}} = conn, _params) do
    json(conn, simulation_response(screen_id, variant))
  end

  def show_pending(%{assigns: %{screen_id: screen_id, screen: screen}} = conn, _params) do
    screen_data = ScreenData.get(screen_id, pending_config: screen)
    json(conn, %{@base_response | data: screen_data})
  end

  def simulation_pending(%{assigns: %{screen_id: screen_id, screen: screen}} = conn, _params) do
    screen_data = ScreenData.simulation(screen_id, pending_config: screen)
    json(conn, %{@base_response | data: screen_data})
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

  defp screen_response(screen_id, _, "all" = variant, opts) do
    {default, variants} = ScreenData.variants(screen_id, merge_options(variant, opts))
    Map.put(%{@base_response | data: default}, :variants, variants)
  end

  # See `docs/mercury_api.md`
  defp screen_response(screen_id, %Screen{vendor: :mercury}, variant, opts) do
    %{full_page: data, flex_zone: flex_zone} =
      ScreenData.simulation(screen_id, merge_options(variant, opts))

    Map.merge(%{@base_response | data: data}, %{flex_zone: flex_zone})
  end

  defp screen_response(screen_id, _, variant, opts) do
    data = ScreenData.get(screen_id, merge_options(variant, opts))
    %{@base_response | data: data}
  end

  defp merge_options(variant, opts) do
    Keyword.put(opts, :generator_variant, variant)
  end

  # See `docs/mercury_api.md`
  defp put_extra_fields(response, screen_id, %Screen{vendor: :mercury}) do
    response
    |> Map.put(:audio_data, fetch_ssml(screen_id))
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

  defp simulation_response(screen_id, "all") do
    {default, variants} = ScreenData.simulation_variants(screen_id)
    Map.put(%{@base_response | data: default}, :variants, variants)
  end

  defp simulation_response(screen_id, variant) do
    %{@base_response | data: ScreenData.simulation(screen_id, generator_variant: variant)}
  end
end
