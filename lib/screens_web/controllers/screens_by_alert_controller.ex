defmodule ScreensWeb.ScreensByAlertController do
  use ScreensWeb, :controller

  alias Screens.ScreensByAlert

  def index(conn, %{"ids" => alert_ids_string}) do
    if alert_ids_string == "" do
      json(conn, [])
    else
      screens_by_alerts =
        alert_ids_string
        |> String.split(",")
        |> Enum.map(fn alert_id ->
          ScreensByAlert.get_screens_by_alert(alert_id)
        end)

      json(conn, screens_by_alerts)
    end
  end

  def index(conn, _) do
    json(conn, [])
  end
end
