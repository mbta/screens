defmodule Screens.V2.CandidateGenerator.Widgets.Alerts do
  @moduledoc false

  alias Screens.Alerts.Alert
  alias Screens.Config.Screen
  alias Screens.Config.V2.{Alerts, BusEink, BusShelter, GlEink}
  alias Screens.RoutePatterns.RoutePattern
  alias Screens.Routes.Route
  alias Screens.Util
  alias Screens.V2.WidgetInstance.Alert, as: AlertWidget

  @alert_supporting_screen_types [BusEink, BusShelter, GlEink]

  @relevant_effects MapSet.new(
                      ~w[shuttle station_closure stop_closure suspension detour stop_moved snow_route elevator_closure]a
                    )

  @spec alert_instances(Screen.t()) :: list(AlertWidget.t())
  def alert_instances(
        %Screen{app_params: %app{alerts: %Alerts{stop_id: stop_id}}} = config,
        now \\ DateTime.utc_now(),
        fetch_routes_at_stop_fn \\ &Route.fetch_routes_at_stop/2,
        fetch_stop_sequences_through_stop_fn \\ &RoutePattern.fetch_stop_sequences_through_stop/1,
        fetch_alerts_by_stop_and_route_fn \\ &Alert.fetch_by_stop_and_route/2
      )
      when app in @alert_supporting_screen_types do
    with {:ok, routes_at_stop} <- fetch_routes_at_stop_fn.(stop_id, now),
         {:ok, stop_sequences} <- fetch_stop_sequences_through_stop_fn.(stop_id),
         reachable_stop_ids = local_and_downstream_stop_ids(stop_sequences, stop_id),
         route_ids_at_stop = Enum.map(routes_at_stop, & &1.route_id),
         {:ok, alerts} <-
           fetch_alerts_by_stop_and_route_fn.(reachable_stop_ids, route_ids_at_stop) do
      alerts
      |> filter_alerts(reachable_stop_ids, route_ids_at_stop)
      |> Enum.map(fn alert ->
        %AlertWidget{
          alert: alert,
          screen: config,
          routes_at_stop: routes_at_stop,
          stop_sequences: stop_sequences,
          now: now
        }
      end)
    else
      :error -> []
    end
  end

  @doc """
  Filters out alerts whose effects we are not interested in, as well as those that do not inform at least one of:
  - an entire route type, e.g. bus or light rail
  - a route that serves the home stop, scoped to either the home stop or a downstream stop
  - a downstream stop or the home stop
  - a route that serves the home stop

  (list describes the `relevant_ie?` function clauses in order)
  """
  def filter_alerts(alerts, stop_ids, route_ids) do
    stop_id_set = MapSet.new(stop_ids)
    route_id_set = MapSet.new(route_ids)

    relevant_ie? = fn
      %{route_type: route_type, stop: nil, route: nil} when not is_nil(route_type) ->
        true

      %{stop: stop, route: route} when not is_nil(stop) and not is_nil(route) ->
        stop in stop_id_set and route in route_id_set

      %{stop: stop, route: nil} ->
        stop in stop_id_set

      %{stop: nil, route: route} ->
        route in route_id_set

      _ ->
        false
    end

    alerts
    |> Stream.filter(&(&1.effect in @relevant_effects))
    |> Stream.filter(&Enum.any?(&1.informed_entities, relevant_ie?))
    |> Enum.to_list()
  end

  defp local_and_downstream_stop_ids(stop_sequences, home_stop) do
    downstream_stop_ids =
      stop_sequences
      |> Enum.flat_map(&Util.slice_after(&1, home_stop))
      |> Enum.uniq()

    [home_stop | downstream_stop_ids]
  end
end
