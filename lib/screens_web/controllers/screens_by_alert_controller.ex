defmodule ScreensWeb.ScreensByAlertController do
  use ScreensWeb, :controller

  alias Screens.ScreensByAlert

  # `ids` must be a comma-separated list of integers.
  # If any item in the list is an invalid integer, 400 is returned.
  def index(conn, %{"ids" => alert_ids_string}) do
    alert_ids =
      alert_ids_string
      |> String.split(",", trim: true)
      |> Enum.map(&String.trim/1)

    if valid_alert_ids_param?(alert_ids) do
      json(conn, ScreensByAlert.get_screens_by_alert(alert_ids))
    else
      send_resp(conn, 400, "Invalid alert ID found")
    end
  end

  def index(conn, params) when map_size(params) == 0 do
    case Screens.Alerts.Alert.fetch(field: "id") do
      {:ok, alerts} ->
        screens_by_alert =
          alerts
          |> Enum.map(& &1.id)
          |> ScreensByAlert.get_screens_by_alert()

        json(conn, screens_by_alert)

      :error ->
        json(conn, %{})
    end
  end

  def index(conn, _) do
    send_resp(conn, 400, "Invalid query parameter(s)")
  end

  defp valid_alert_ids_param?(alert_ids) do
    Enum.all?(alert_ids, &match?({_n, ""}, Integer.parse(&1)))
  end
end
