defmodule Screens.V2.CandidateGenerator.Widgets.ReconstructedAlert do
  @moduledoc false

  alias Screens.Config.Screen
  alias Screens.Config.V2.Header.CurrentStopId
  alias Screens.Config.V2.PreFare
  alias Screens.V2.WidgetInstance.ReconstructedAlert

  def reconstructed_alert_instances(%Screen{
        app_params: %PreFare{header: %CurrentStopId{stop_id: _stop_id}}
      }) do
    # Given the stop id, determine relevant routes
    temp_route_ids = ["Red", "Green-B", "Green-C", "Green-D", "Green-E"]

    # Given route ids, fetch alerts
    case Screens.Alerts.Alert.fetch(route_ids: temp_route_ids) do
      {:ok, alerts} ->
        Enum.map(
          alerts,
          fn alert -> %ReconstructedAlert{alert: alert} end
        )

      :error ->
        []
    end
  end
end
