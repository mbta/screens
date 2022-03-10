defmodule Screens.V2.CandidateGenerator.Widgets.ReconstructedAlert do
  @moduledoc false

  alias Screens.Alerts.Alert
  alias Screens.Config.Screen
  alias Screens.Config.V2.Header.CurrentStopId
  alias Screens.Config.V2.PreFare
  alias Screens.Routes.Route
  alias Screens.V2.WidgetInstance.ReconstructedAlert

  @relevant_effects ~w[shuttle suspension station_closure delay]a

  @doc """
  Given the stop_id defined in the header, determine relevant routes
  Given the routes, fetch all alerts for the route
  """
  def reconstructed_alert_instances(
        %Screen{app_params: %PreFare{header: %CurrentStopId{stop_id: stop_id}}},
        now \\ DateTime.utc_now(),
        fetch_routes_at_stop_fn \\ &Route.fetch_routes_at_stop/3,
        fetch_alerts_fn \\ &Alert.fetch/1
      ) do
    with {:ok, routes_at_stop} <- fetch_routes_at_stop_fn.(stop_id, now, :subway),
         route_ids_at_stop = Enum.map(routes_at_stop, & &1.route_id),
         {:ok, alerts} <- fetch_alerts_fn.(route_ids: route_ids_at_stop) do
      alerts
      |> Enum.filter(fn alert ->
        Enum.member?(@relevant_effects, Map.get(alert, :effect))
      end)
      |> Enum.map(fn alert -> %ReconstructedAlert{alert: alert} end)
    else
      :error -> []
    end
  end
end
