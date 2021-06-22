defmodule Screens.V2.CandidateGenerator.Helpers.Alerts do
  @moduledoc false

  alias Screens.Alerts.Alert
  alias Screens.Config.Screen
  alias Screens.Config.V2.{Alerts, BusEink, BusShelter, GlEink}
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
        today \\ Date.utc_today(),
        fetch_routes_at_stop_fn \\ &fetch_routes_at_stop/2,
        fetch_stop_sequences_fn \\ &fetch_stop_sequences_through_stop/1,
        fetch_alerts_fn \\ &fetch_alerts/2
      )
      when app in @alert_supporting_screen_types do
    with {:ok, routes_at_stop} <- fetch_routes_at_stop_fn.(stop_id, today),
         {:ok, stop_sequences} <- fetch_stop_sequences_fn.(stop_id),
         reachable_stop_ids = [stop_id | unique_downstream_stop_ids(stop_sequences, stop_id)],
         route_ids_at_stop = Enum.map(routes_at_stop, & &1.route_id),
         {:ok, alerts} <- fetch_alerts_fn.(reachable_stop_ids, route_ids_at_stop) do
      Enum.map(alerts, fn alert ->
        %AlertWidget{
          alert: alert,
          screen: config,
          routes_at_stop: routes_at_stop,
          stop_sequences: stop_sequences
        }
      end)
    else
      :error -> []
    end
  end

  @spec fetch_stop_sequences_through_stop(String.t()) :: {:ok, list(list(String.t()))} | :error
  def fetch_stop_sequences_through_stop(stop_id, get_json_fn \\ &Screens.V3Api.get_json/2) do
    case get_json_fn.("route_patterns", %{
           "include" => "representative_trip.stops",
           "filter[stop]" => stop_id
         }) do
      {:ok, result} ->
        stop_sequences =
          get_in(result, [
            "included",
            Access.filter(&(&1["type"] == "trip")),
            "relationships",
            "stops",
            "data",
            Access.all(),
            "id"
          ])

        {:ok, stop_sequences}

      _ ->
        :error
    end
  end

  @spec fetch_routes_at_stop(String.t(), Date.t()) ::
          {:ok, list(%{route_id: String.t(), active?: boolean()})} | :error
  def fetch_routes_at_stop(
        stop_id,
        today,
        fetch_all_route_ids_fn \\ &fetch_all_route_ids/1,
        fetch_active_route_ids_fn \\ &fetch_active_route_ids/2
      ) do
    with {:ok, all_route_ids} <- fetch_all_route_ids_fn.(stop_id),
         {:ok, active_route_ids} <- fetch_active_route_ids_fn.(stop_id, today) do
      active_set = MapSet.new(active_route_ids)

      routes_at_stop =
        Enum.map(all_route_ids, &%{route_id: &1, active?: MapSet.member?(active_set, &1)})

      {:ok, routes_at_stop}
    else
      :error -> :error
    end
  end

  @spec fetch_alerts(list(String.t()), list(String.t())) :: {:ok, list(Alert.t())} | :error
  def fetch_alerts(
        stop_ids,
        route_ids,
        fetch_fn \\ &Alert.fetch/1,
        filter_fn \\ &filter_alerts/3
      ) do
    with {:ok, stop_based_alerts} <- fetch_fn.(stop_ids: stop_ids, route_ids: route_ids),
         {:ok, route_based_alerts} <- fetch_fn.(route_ids: route_ids) do
      merged_alerts =
        [stop_based_alerts, route_based_alerts]
        |> Enum.concat()
        |> Enum.uniq_by(& &1.id)
        |> filter_fn.(stop_ids, route_ids)

      {:ok, merged_alerts}
    else
      :error -> :error
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
    |> Enum.filter(&(&1.effect in @relevant_effects))
    |> Enum.filter(&Enum.any?(&1.informed_entities, relevant_ie?))
  end

  defp fetch_all_route_ids(stop_id) do
    case Route.fetch(stop_id: stop_id) do
      {:ok, routes} -> {:ok, Enum.map(routes, & &1.id)}
      :error -> :error
    end
  end

  defp fetch_active_route_ids(stop_id, today) do
    case Route.fetch(stop_id: stop_id, date: today) do
      {:ok, routes} -> {:ok, Enum.map(routes, & &1.id)}
      :error -> :error
    end
  end

  defp unique_downstream_stop_ids(stop_sequences, home_stop) do
    stop_sequences
    |> Enum.flat_map(&Util.slice_after(&1, home_stop))
    |> Enum.uniq()
  end
end
