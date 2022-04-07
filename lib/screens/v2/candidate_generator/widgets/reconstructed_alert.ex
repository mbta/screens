defmodule Screens.V2.CandidateGenerator.Widgets.ReconstructedAlert do
  @moduledoc false

  alias Screens.Alerts.Alert
  alias Screens.Config.Screen
  alias Screens.Config.V2.Header.CurrentStopId
  alias Screens.Config.V2.PreFare
  alias Screens.RoutePatterns.RoutePattern
  alias Screens.Routes.Route
  alias Screens.V2.WidgetInstance.Common.BaseAlert
  alias Screens.V2.WidgetInstance.ReconstructedAlert

  @relevant_effects ~w[shuttle suspension station_closure delay]a

  @doc """
  Given the stop_id defined in the header, determine relevant routes
  Given the routes, fetch all alerts for the route
  """
  def reconstructed_alert_instances(
        %Screen{
          app_params: %PreFare{reconstructed_alert_widget: %CurrentStopId{stop_id: stop_id}}
        } = config,
        now \\ DateTime.utc_now(),
        fetch_routes_by_stop_fn \\ &Route.fetch_routes_by_stop/3,
        fetch_stop_sequences_by_stop_fn \\ &RoutePattern.fetch_parent_station_sequences_through_stop/2,
        fetch_alerts_fn \\ &Alert.fetch/1
      ) do
    # Filtering by subway and light_rail types
    with {:ok, routes_at_stop} <- fetch_routes_by_stop_fn.(stop_id, now, [0, 1]),
         route_ids_at_stop = Enum.map(routes_at_stop, & &1.route_id),
         {:ok, alerts} <- fetch_alerts_fn.(route_ids: route_ids_at_stop),
         {:ok, station_sequences} <-
           fetch_stop_sequences_by_stop_fn.(stop_id, route_ids_at_stop) do
      alerts
      |> Enum.filter(&relevant?(&1, config, station_sequences, routes_at_stop))
      |> Enum.map(fn alert ->
        %ReconstructedAlert{
          screen: config,
          alert: alert,
          now: now,
          stop_sequences: station_sequences,
          routes_at_stop: routes_at_stop
        }
      end)
    else
      :error -> []
    end
  end

  defp relevant?(
         %Alert{severity: severity, effect: effect} = alert,
         config,
         stop_sequences,
         routes_at_stop
       ) do
    Enum.member?(@relevant_effects, effect) and
      case BaseAlert.location(%ReconstructedAlert{
             screen: config,
             alert: alert,
             stop_sequences: stop_sequences,
             routes_at_stop: routes_at_stop,
             now: DateTime.utc_now()
           }) do
        location when location in [:downstream, :upstream] ->
          true

        :inside ->
          effect != :delay or severity > 3

        location when location in [:boundary_upstream, :boundary_downstream] ->
          effect != :station_closure and (effect != :delay or severity > 3)

        _ ->
          false
      end
  end
end
