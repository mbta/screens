defmodule Screens.V2.CandidateGenerator.Widgets.SubwayStatus do
  @moduledoc false

  alias Screens.V2.WidgetInstance.SubwayStatus

  def subway_status_instances(config) do
    route_ids = ["Blue", "Orange", "Red", "Green-B", "Green-C", "Green-D", "Green-E"]

    case Screens.Alerts.Alert.fetch(route_ids: route_ids) do
      {:ok, alerts} -> [%SubwayStatus{screen: config, subway_alerts: alerts}]
      :error -> []
    end
  end
end
