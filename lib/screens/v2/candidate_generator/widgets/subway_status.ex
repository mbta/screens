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
      |> Enum.filter(&(relevant_alert?(&1) and Alert.happening_now?(&1, now)))
      |> Enum.map(&append_context(&1, fetch_subway_platforms_for_stop_fn))

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

  defp append_context(
         %Alert{effect: :station_closure} = alert,
         fetch_subway_platforms_for_stop_fn
       ) do
    informed_parent_stations = Alert.informed_parent_stations(alert)

    all_platforms_at_informed_station =
      Enum.flat_map(informed_parent_stations, &fetch_subway_platforms_for_stop_fn.(&1.stop))

    %SubwayStatus.SubwayStatusAlert{
      alert: alert,
      context: %{all_platforms_at_informed_station: all_platforms_at_informed_station}
    }
  end

  defp append_context(alert, _), do: struct(SubwayStatus.SubwayStatusAlert, alert: alert)
end
