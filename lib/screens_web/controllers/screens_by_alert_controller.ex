defmodule ScreensWeb.ScreensByAlertController do
  use ScreensWeb, :controller

  alias Screens.ScreensByAlert

  def index(conn, %{"ids" => ""}) do
    json(conn, %{})
  end

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

  def index(conn, _) do
    json(conn, %{})
  end

  defp valid_alert_ids_param?(alert_ids) do
    Enum.all?(alert_ids, &match?({_n, ""}, Integer.parse(&1)))
  end
end
