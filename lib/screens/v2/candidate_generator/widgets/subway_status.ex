defmodule Screens.V2.CandidateGenerator.Widgets.SubwayStatus do
  @moduledoc false

  alias Screens.Alerts.Alert
  alias Screens.Stops.Stop
  alias Screens.V2.WidgetInstance.SubwayStatus

  def subway_status_instances(
        config,
        now \\ DateTime.utc_now(),
        fetch_subway_platforms_for_stop_fn \\ &Stop.fetch_subway_platforms_for_stop/1
      ) do
    route_ids = ["Blue", "Orange", "Red", "Green-B", "Green-C", "Green-D", "Green-E"]

    {:ok, alerts} = Screens.Alerts.Alert.fetch(route_ids: route_ids)

    relevant_alerts =
      alerts
      |> Enum.filter(&relevant?(&1, now))
      |> Enum.map(&append_context(&1, fetch_subway_platforms_for_stop_fn))

    [%SubwayStatus{screen: config, subway_alerts: relevant_alerts}]
  end

  def relevant?(alert, now) do
    relevant_effect?(alert) and Alert.happening_now?(alert, now) and not suppressed?(alert)
  end

  # Omit up to 10 minute delays.
  defp relevant_effect?(%Alert{effect: :delay, severity: severity}), do: severity >= 3

  defp relevant_effect?(%Alert{effect: effect}),
    do: effect in [:suspension, :shuttle, :station_closure]

  defp suppressed?(_alert), do: false

  defp append_context(
         %Alert{effect: :station_closure} = alert,
         fetch_subway_platforms_for_stop_fn
       ) do
    informed_parent_stations = Alert.informed_parent_stations(alert)

    all_platforms_at_informed_station =
      case informed_parent_stations do
        [informed_parent_station] ->
          fetch_subway_platforms_for_stop_fn.(informed_parent_station.stop)

        _ ->
          []
      end

    %SubwayStatus.SubwayStatusAlert{
      alert: alert,
      context: %{all_platforms_at_informed_station: all_platforms_at_informed_station}
    }
  end

  defp append_context(alert, _), do: struct(SubwayStatus.SubwayStatusAlert, alert: alert)
end
