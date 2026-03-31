defmodule Screens.V2.CandidateGenerator.Widgets.SubwayStatus do
  @moduledoc false

  alias Screens.Alerts.Alert
  alias Screens.V2.WidgetInstance.SubwayStatus

  def subway_status_instances(config, now \\ DateTime.utc_now()) do
    route_ids = ["Blue", "Orange", "Red", "Green-B", "Green-C", "Green-D", "Green-E", "Mattapan"]

    {:ok, alerts} = Screens.Alerts.Alert.fetch(route_ids: route_ids)

    relevant_alerts =
      alerts
      |> Enum.filter(&(relevant_alert?(&1) and Alert.happening_now?(&1, now)))
      |> Alert.consolidate_whole_route_delays()
      |> Enum.map(&%SubwayStatus.SubwayStatusAlert{alert: &1})

    [%SubwayStatus{screen: config, subway_alerts: relevant_alerts}]
  end

  defp relevant_alert?(%Alert{effect: effect})
       when effect in ~w[suspension shuttle station_closure]a,
       do: true

  # Always include single-tracking alerts even at informational severity.
  defp relevant_alert?(%Alert{effect: :delay, cause: :single_tracking}), do: true

  defp relevant_alert?(%Alert{effect: effect, severity: severity})
       when effect in ~w[delay service_change]a and severity > 1,
       do: true

  defp relevant_alert?(%Alert{}), do: false
end
