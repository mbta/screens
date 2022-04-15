defmodule Screens.V2.CandidateGenerator.Widgets.ReconstructedAlert do
  @moduledoc false

  alias Screens.Alerts.Alert
  alias Screens.Config.Screen
  alias Screens.Config.V2.Header.CurrentStopId
  alias Screens.Config.V2.PreFare
  alias Screens.RoutePatterns.RoutePattern
  alias Screens.Routes.Route
  alias Screens.Stops.Stop
  alias Screens.Util
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
        fetch_alerts_fn \\ &Alert.fetch/1,
        fetch_stop_name_fn \\ &Stop.fetch_stop_name/1
      ) do
    # Filtering by subway and light_rail types
    with {:ok, routes_at_stop} <- fetch_routes_by_stop_fn.(stop_id, now, [0, 1]),
         route_ids_at_stop = Enum.map(routes_at_stop, & &1.route_id),
         {:ok, alerts} <- fetch_alerts_fn.(route_ids: route_ids_at_stop),
         {:ok, station_sequences} <-
           fetch_stop_sequences_by_stop_fn.(stop_id, route_ids_at_stop) do
      alerts
      |> Enum.filter(&relevant?(&1, config, station_sequences, routes_at_stop, now))
      |> Enum.map(fn alert ->
        %ReconstructedAlert{
          screen: config,
          alert: alert,
          now: now,
          stop_sequences: station_sequences,
          routes_at_stop: routes_at_stop,
          informed_stations_string: get_stations(alert, fetch_stop_name_fn)
        }
      end)
    else
      :error -> []
    end
  end

  defp relevant?(
         %Alert{effect: effect} = alert,
         config,
         stop_sequences,
         routes_at_stop,
         now
       ) do
    reconstructed_alert = %ReconstructedAlert{
      screen: config,
      alert: alert,
      stop_sequences: stop_sequences,
      routes_at_stop: routes_at_stop,
      now: now
    }

    relevant_effect?(effect) and relevant_location?(reconstructed_alert) and
      Alert.happening_now?(alert, now)
  end

  defp relevant_effect?(effect) do
    Enum.member?(@relevant_effects, effect)
  end

  defp relevant_location?(%ReconstructedAlert{alert: alert} = reconstructed_alert) do
    case BaseAlert.location(reconstructed_alert) do
      location when location in [:downstream, :upstream] ->
        true

      :inside ->
        alert.effect != :delay or alert.severity > 3

      location when location in [:boundary_upstream, :boundary_downstream] ->
        alert.effect != :station_closure and (alert.effect != :delay or alert.severity > 3)

      _ ->
        false
    end
  end

  defp get_stations(alert, fetch_stop_name_fn) do
    %{alert: alert}
    |> BaseAlert.informed_entities()
    |> Enum.map(fn %{stop: stop_id} -> stop_id end)
    |> Enum.filter(&String.starts_with?(&1, "place-"))
    |> Enum.uniq()
    |> Enum.flat_map(
      &case fetch_stop_name_fn.(&1) do
        :error -> []
        name -> [name]
      end
    )
    |> Util.format_name_list_to_string()
  end
end
