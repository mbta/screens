defmodule ScreensWeb.V2.ScreenApiController do
  use ScreensWeb, :controller

  alias Phoenix.View
  alias Screens.V2.ScreenData
  alias ScreensConfig.Screen
  alias ScreensWeb.Plug.ScreenRequest

  import Screens.Inject
  @build_info injected(Screens.Util.BuildInfo)

  @base_response %{data: nil, disabled: false, force_reload: false}

  @show_actions [:show, :show_dup, :simulation]

  plug Corsica, [origins: "*"] when action in [:show_dup, :log_frontend_error]
  plug ScreenRequest, [type: :data] when action in @show_actions
  plug :disabled_response when action in @show_actions
  plug :outdated_response when action in @show_actions

  def show(%{assigns: %{screen_id: id, screen: screen}} = conn, _params) do
    json(conn, screen_response(id, screen) |> put_extra_fields(id, screen))
  end

  def show_dup(conn, params), do: show(conn, params)

  def simulation(%{assigns: %{screen_id: id, screen: screen}} = conn, _params) do
    json(conn, %{@base_response | data: ScreenData.simulation(id, screen)})
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

  # See `docs/mercury_api.md`
  defp screen_response(id, %Screen{vendor: :mercury} = screen) do
    %{full_page: data, flex_zone: flex_zone} = ScreenData.simulation(id, screen)
    Map.merge(%{@base_response | data: data}, %{flex_zone: flex_zone})
  end

  defp screen_response(id, screen) do
    %{@base_response | data: ScreenData.get(id, screen)}
  end

  # See `docs/mercury_api.md`
  defp put_extra_fields(response, id, %Screen{vendor: :mercury} = screen) do
    response
    |> Map.put(:audio_data, fetch_ssml(id, screen))
    |> Map.put(:last_deploy_timestamp, @build_info.build_identifier())
  end

  defp put_extra_fields(response, _id, _screen), do: response

  defp fetch_ssml(id, screen) do
    case ScreenData.audio(id, screen) do
      [] ->
        ""

      data ->
        View.render_to_string(ScreensWeb.V2.AudioView, "index.ssml", widget_audio_data: data)
    end
  end

  defp disabled_response(%{assigns: %{screen: %Screen{disabled: true}}} = conn, _) do
    Logger.metadata(response_type: :disabled)
    conn |> json(%{@base_response | disabled: true}) |> halt()
  end

  defp disabled_response(conn, _), do: conn

  # The packaged client can't reload the page to update itself; this would just reload the local
  # copy of the code, resulting in an infinite loop. Compatibility and versioning of the packaged
  # client is handled manually.
  defp outdated_response(%{params: %{"last_refresh" => "packaged"}} = conn, _), do: conn

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
        [@build_info.build_identifier(), refresh_if_loaded_before]
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
