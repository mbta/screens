defmodule ScreensWeb.ScreensByAlertController do
  use ScreensWeb, :controller

  alias Screens.ScreensByAlert

  def index(conn, %{"ids" => ""}) do
    json(conn, %{})
  end

  def index(conn, %{"ids" => alert_ids_string}) do
    alert_ids =
      alert_ids_string
      |> String.trim()
      |> String.split(",")

    if valid_alert_ids_param?(alert_ids) do
      json(conn, ScreensByAlert.get_screens_by_alert(alert_ids))
    else
      Plug.Conn.send_resp(conn, 400, "Invalid alert ID found")
    end
  end

  def index(conn, _) do
    json(conn, %{})
  end

  defp valid_alert_ids_param?(alert_ids) do
    Enum.all?(alert_ids, &(Integer.parse(&1) != :error))
  end
end
