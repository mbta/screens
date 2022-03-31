defmodule Screens.V2.CandidateGenerator.Widgets.ReconstructedAlert do
  @moduledoc false

  alias Screens.Alerts.Alert
  alias Screens.Config.Screen
  alias Screens.Config.V2.Header.CurrentStopId
  alias Screens.Config.V2.PreFare
  alias Screens.RoutePatterns.RoutePattern
  alias Screens.Routes.Route
  alias Screens.V2.WidgetInstance.ReconstructedAlert

  @relevant_effects ~w[shuttle suspension station_closure delay]a

  @doc """
  Given the stop_id defined in the header, determine relevant routes
  Given the routes, fetch all alerts for the route
  """
  def reconstructed_alert_instances(
        %Screen{app_params: %PreFare{alert_widget: %CurrentStopId{stop_id: stop_id}}} = config,
        now \\ DateTime.utc_now(),
        fetch_routes_by_stop_fn \\ &Route.fetch_routes_by_stop/3,
        fetch_stop_sequences_by_stop_fn \\ &RoutePattern.fetch_stop_sequences_through_stop/2,
        fetch_alerts_fn \\ &Alert.fetch/1,
        get_parent_station_id_fn \\ &get_parent_station/1
      ) do
    # Filtering by subway and light_rail types
    with {:ok, routes_at_stop} <- fetch_routes_by_stop_fn.(stop_id, now, [0, 1]),
         route_ids_at_stop = Enum.map(routes_at_stop, & &1.route_id),
         {:ok, alerts} <- fetch_alerts_fn.(route_ids: route_ids_at_stop),
         {:ok, stop_sequences} <- fetch_stop_sequences_by_stop_fn.(stop_id, route_ids_at_stop) do
      station_sequences =
        stop_sequences
        |> Enum.map(fn stop_sequence ->
          stop_sequence
          |> Enum.map(fn stop ->
            case get_parent_station_id_fn.(stop) do
              {:ok, parent_stop} -> parent_stop
              :error -> nil
            end
          end)
        end)
        # Dedup the stop sequences (both directions are listed, but we only need 1)
        |> Enum.uniq_by(&MapSet.new/1)

      alerts
      |> Enum.filter(fn alert ->
        Enum.member?(@relevant_effects, Map.get(alert, :effect))
      end)
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

  # This slows things down... Should we store this like we do for elevator closures?
  # Also, handle errors better
  def get_parent_station(stop) do
    case Screens.V3Api.get_json("stops/" <> stop) do
      {:ok, result} ->
        parent_stop =
          get_in(result, [
            "data",
            "relationships",
            "parent_station",
            "data",
            "id"
          ])

        {:ok, parent_stop}

      _ ->
        :error
    end
  end
end
