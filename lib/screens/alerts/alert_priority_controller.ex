defmodule ScreensWeb.AlertPriorityController do
  use ScreensWeb, :controller

  def show(conn, %{"id" => screen_id}) do
    screen_data =
      :screens
      |> Application.get_env(:screen_data)
      |> Map.get(screen_id)

    data =
      case screen_data do
        %{app_id: "bus_eink", stop_id: stop_id} ->
          Screens.Alerts.Alert.priority_by_stop_id(stop_id)

        %{app_id: "gl_eink_single", route_id: route_id, stop_id: stop_id} ->
          Screens.Alerts.Alert.priority_by_route_id(route_id, stop_id)

        %{app_id: "gl_eink_double", route_id: route_id, stop_id: stop_id} ->
          Screens.Alerts.Alert.priority_by_route_id(route_id, stop_id)
      end

    json(conn, data)
  end
end
