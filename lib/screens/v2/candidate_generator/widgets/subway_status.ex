defmodule Screens.V2.CandidateGenerator.Widgets.SubwayStatus do
  @moduledoc false

  alias Screens.Alerts.Alert
  alias Screens.V2.WidgetInstance.SubwayStatus

  def subway_status_instances(config, now \\ DateTime.utc_now()) do
    route_ids = ["Blue", "Orange", "Red", "Green-B", "Green-C", "Green-D", "Green-E"]

    case Screens.Alerts.Alert.fetch(route_ids: route_ids) do
      {:ok, alerts} ->
        relevant_alerts = Enum.filter(alerts, &relevant?(&1, now))
        [%SubwayStatus{screen: config, subway_alerts: relevant_alerts}]

      :error ->
        []
    end
  end

  def relevant?(alert, now) do
    relevant_effect?(alert) and Alert.happening_now?(alert, now)
  end

  # Omit up to 10 minute delays.
  defp relevant_effect?(%Alert{effect: :delay, severity: severity}), do: severity >= 3

  defp relevant_effect?(%Alert{effect: effect}),
    do: effect in [:suspension, :shuttle, :station_closure]
end
