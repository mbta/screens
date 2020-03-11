defmodule ScreensWeb.ScreenApiController do
  use ScreensWeb, :controller

  def show(conn, %{"id" => screen_id, "version" => version}) do
    %{app_id: app_id, stop_id: stop_id} =
      :screens
      |> Application.get_env(:screen_data)
      |> Map.get(screen_id)

    data =
      case app_id do
        "bus_eink" ->
          Screens.ScreenData.by_stop_id_with_override_and_version(stop_id, screen_id, version)

        "gl_eink_single" ->
          Screens.GLScreenData.by_stop_id_with_override_and_version(stop_id, screen_id, version)

        "gl_eink_double" ->
          Screens.GLScreenData.by_stop_id_with_override_and_version(stop_id, screen_id, version)
      end

    json(conn, data)
  end
end
