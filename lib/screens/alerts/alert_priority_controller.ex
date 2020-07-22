defmodule ScreensWeb.AlertPriorityController do
  use ScreensWeb, :controller

  alias Screens.Config.{Bus, Gl, State}

  def show(conn, %{"id" => screen_id}) do
    data =
      case State.app_params(screen_id) do
        %Bus{stop_id: stop_id} ->
          Screens.Alerts.Alert.priority_by_stop_id(stop_id)

        %Gl{route_id: route_id, stop_id: stop_id} ->
          Screens.Alerts.Alert.priority_by_route_id(route_id, stop_id)
      end

    json(conn, data)
  end
end
