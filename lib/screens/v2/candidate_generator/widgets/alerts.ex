defmodule Screens.V2.CandidateGenerator.Widgets.Alerts do
  @moduledoc false

  alias Screens.Alerts.Alert
  alias Screens.LocationContext
  alias Screens.V2.WidgetInstance.Alert, as: AlertWidget
  alias ScreensConfig.{Alerts, MultiStopAlerts}
  alias ScreensConfig.Screen

  @relevant_effects MapSet.new(
                      ~w[shuttle station_closure stop_closure suspension detour stop_moved snow_route elevator_closure]a
                    )

  @spec alert_instances(Screen.t()) :: list(AlertWidget.t())
  def alert_instances(
        %Screen{app_params: %app{alerts: alerts_config}} = config,
        now \\ DateTime.utc_now(),
        fetch_alerts_by_stop_and_route_fn \\ &Alert.fetch_by_stop_and_route/2,
        fetch_location_context_fn \\ &LocationContext.fetch/3
      ) do
    stop_ids =
      case alerts_config do
        %Alerts{stop_id: stop_id} -> [stop_id]
        %MultiStopAlerts{stop_ids: stop_ids} -> stop_ids
      end

    with {:ok, location_context} <- fetch_location_context_fn.(app, stop_ids, now),
         reachable_stop_ids = local_and_downstream_stop_ids(location_context, stop_ids),
         route_ids <- LocationContext.route_ids(location_context),
         {:ok, alerts} <- fetch_alerts_by_stop_and_route_fn.(reachable_stop_ids, route_ids) do
      alerts
      |> relevant_alerts(reachable_stop_ids, route_ids, now)
      |> Enum.map(
        &%AlertWidget{alert: &1, screen: config, location_context: location_context, now: now}
      )
    else
      :error -> []
    end
  end

  @doc """
  Filters out alerts whose effects we are not interested in, as well as those that do not inform
  at least one of:

  - an entire route type, e.g. bus or light rail
  - a route that serves the local stops, scoped to local or downstream stops
  - a local or downstream stop
  - a route that serves a local stop

  (list describes the `relevant_ie?` function clauses in order)
  """
  def relevant_alerts(alerts, stop_ids, route_ids, now) do
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
    |> Stream.filter(&Alert.happening_now?(&1, now))
    |> Stream.filter(&(&1.effect in @relevant_effects))
    |> Stream.filter(&Enum.any?(&1.informed_entities, relevant_ie?))
    |> Enum.to_list()
  end

  defp local_and_downstream_stop_ids(
         %LocationContext{downstream_stops: downstream_stops},
         home_stop_ids
       ),
       do: home_stop_ids |> MapSet.new() |> MapSet.union(downstream_stops) |> MapSet.to_list()
end
