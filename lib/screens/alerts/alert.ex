defmodule Screens.Alerts.Alert do
  @moduledoc false

  alias Screens.Routes.Route
  alias Screens.Stops.Stop
  alias Screens.V3Api

  defstruct id: nil,
            cause: nil,
            effect: nil,
            severity: nil,
            header: nil,
            informed_entities: nil,
            active_period: nil,
            lifecycle: nil,
            timeframe: nil,
            created_at: nil,
            updated_at: nil,
            url: nil,
            description: nil

  @type cause ::
          :accident
          | :amtrak
          | :an_earlier_mechanical_problem
          | :an_earlier_signal_problem
          | :autos_impeding_service
          | :coast_guard_restriction
          | :congestion
          | :construction
          | :crossing_malfunction
          | :demonstration
          | :disabled_bus
          | :disabled_train
          | :drawbridge_being_raised
          | :electrical_work
          | :fire
          | :fog
          | :freight_train_interference
          | :hazmat_condition
          | :heavy_ridership
          | :high_winds
          | :holiday
          | :hurricane
          | :ice_in_harbor
          | :maintenance
          | :mechanical_problem
          | :medical_emergency
          | :parade
          | :police_action
          | :power_problem
          | :severe_weather
          | :signal_problem
          | :slippery_rail
          | :snow
          | :special_event
          | :speed_restriction
          | :switch_problem
          | :tie_replacement
          | :track_problem
          | :track_work
          | :traffic
          | :unruly_passenger
          | :weather
          | :unknown

  @type effect ::
          :access_issue
          | :amber_alert
          | :bike_issue
          | :cancellation
          | :delay
          | :detour
          | :dock_issue
          | :dock_closure
          | :elevator_closure
          | :escalator_closure
          | :extra_service
          | :facility_issue
          | :no_service
          | :parking_closure
          | :parking_issue
          | :policy_change
          | :service_change
          | :shuttle
          | :suspension
          | :station_closure
          | :stop_closure
          | :stop_moved
          | :schedule_change
          | :snow_route
          | :station_issue
          | :stop_shoveling
          | :summary
          | :track_change
          | :unknown

  @type informed_entity :: %{
          stop: String.t() | nil,
          route: String.t() | nil,
          route_type: non_neg_integer() | nil
        }

  @type t :: %__MODULE__{
          id: String.t(),
          cause: cause,
          effect: effect,
          severity: integer,
          header: String.t(),
          informed_entities: list(informed_entity()),
          active_period: list(),
          lifecycle: String.t(),
          timeframe: String.t(),
          created_at: DateTime.t(),
          updated_at: DateTime.t(),
          description: String.t()
        }

  def to_map(nil), do: nil

  def to_map(alert) do
    %{
      effect: alert.effect,
      header: alert.header,
      updated_at: DateTime.to_iso8601(alert.updated_at)
    }
  end

  def to_full_map(alert) do
    aps = Enum.map(alert.active_period, &ap_to_map/1)

    %{
      id: alert.id,
      effect: alert.effect,
      severity: alert.severity,
      header: alert.header,
      informed_entities: alert.informed_entities,
      active_period: aps,
      lifecycle: alert.lifecycle,
      timeframe: alert.timeframe,
      created_at: DateTime.to_iso8601(alert.created_at),
      updated_at: DateTime.to_iso8601(alert.updated_at)
    }
  end

  def ap_to_map({nil, end_t}) do
    %{"start" => nil, "end" => DateTime.to_iso8601(end_t)}
  end

  def ap_to_map({start_t, nil}) do
    %{"start" => DateTime.to_iso8601(start_t), "end" => nil}
  end

  def ap_to_map({start_t, end_t}) do
    %{"start" => DateTime.to_iso8601(start_t), "end" => DateTime.to_iso8601(end_t)}
  end

  @effect_order [
    :amber_alert,
    :cancellation,
    :delay,
    :suspension,
    :track_change,
    :detour,
    :shuttle,
    :stop_closure,
    :dock_closure,
    :station_closure,
    :stop_moved,
    :extra_service,
    :schedule_change,
    :service_change,
    :snow_route,
    :stop_shoveling,
    :station_issue,
    :dock_issue,
    :access_issue,
    :policy_change
  ]

  @spec fetch(keyword()) :: {:ok, list(t())} | :error
  def fetch(opts \\ [], get_json_fn \\ &V3Api.get_json/2) do
    params =
      opts
      |> Enum.flat_map(&format_query_param/1)
      |> Enum.into(%{})

    case get_json_fn.("alerts", params) do
      {:ok, result} ->
        {:ok, Screens.Alerts.Parser.parse_result(result)}

      _ ->
        :error
    end
  end

  @doc """
  Convenience for cases when it's safe to treat an API alert data outage
  as if there simply aren't any alerts for the given parameters.

  If the query fails for any reason, an empty list is returned.
  """
  @spec fetch_or_empty_list(keyword()) :: list(t())
  def fetch_or_empty_list(opts \\ []) do
    case fetch(opts) do
      {:ok, alerts} -> alerts
      :error -> []
    end
  end

  @doc """
  Fetches:
  1) alerts filtered by the given list of stops AND the given list of routes
  2) alerts filtered by the given list of routes only

  and merges them into one list.

  NOTE: due to some undocumented logic in the V3 API, filtering by stop also automatically filters
  by routes that serve the stop(s). This hidden filter is merged with our user-supplied route
  filter, which can cause some unwanted alerts to show up in the response.

  As a result, you will likely need to do additional client-side filtering to get the alerts
  you're looking for.
  https://app.asana.com/0/0/1200476247539238/f
  """
  @spec fetch_by_stop_and_route(list(Stop.id()), list(Route.id()), keyword()) ::
          {:ok, list(t())} | :error
  def fetch_by_stop_and_route(stop_ids, route_ids, opts \\ [], get_json_fn \\ &V3Api.get_json/2) do
    with {:ok, stop_based_alerts} <-
           fetch(opts ++ [stop_ids: stop_ids, route_ids: route_ids], get_json_fn),
         {:ok, route_based_alerts} <- fetch(opts ++ [route_ids: route_ids], get_json_fn) do
      merged_alerts =
        [stop_based_alerts, route_based_alerts]
        |> Enum.concat()
        |> Enum.uniq_by(& &1.id)

      {:ok, merged_alerts}
    else
      :error -> :error
    end
  end

  defp format_query_param({:fields, fields}) when is_list(fields) do
    [
      {"fields[alert]", Enum.join(fields, ",")}
    ]
  end

  defp format_query_param({:field, field}) when is_binary(field) do
    format_query_param({:fields, [field]})
  end

  defp format_query_param({:stop_ids, stop_ids}) when is_list(stop_ids) do
    [
      {"filter[stop]", Enum.join(stop_ids, ",")}
    ]
  end

  defp format_query_param({:stop_id, stop_id}) when is_binary(stop_id) do
    format_query_param({:stop_ids, [stop_id]})
  end

  defp format_query_param({:route_ids, route_ids}) when is_list(route_ids) do
    [
      {"filter[route]", Enum.join(route_ids, ",")}
    ]
  end

  defp format_query_param({:route_id, route_id}) when is_binary(route_id) do
    format_query_param({:route_ids, [route_id]})
  end

  defp format_query_param({:route_types, route_types}) do
    route_type_ids = Enum.map_join(route_types, ",", &Screens.RouteType.to_id/1)

    [
      {"filter[route_type]", route_type_ids}
    ]
  end

  defp format_query_param({:datetime, datetime}) do
    [{"filter[datetime]", datetime}]
  end

  defp format_query_param(_), do: []

  def fetch_alerts_for_stop_id(stop_id) do
    case Screens.V3Api.get_json("alerts", %{"filter[stop]" => stop_id}) do
      {:ok, result} -> {:ok, result}
      _ -> :error
    end
  end

  def priority_by_stop_id(stop_id) do
    [stop_id: stop_id]
    |> fetch_or_empty_list()
    |> sort(stop_id)
    |> Enum.map(fn alert ->
      %{alert: to_full_map(alert), priority: to_priority_map(alert, stop_id)}
    end)
  end

  def sort(alerts, stop_id) do
    Enum.sort_by(alerts, &sort_key(&1, stop_id))
  end

  def sort_key(alert, stop_id) do
    {
      specificity(alert, stop_id),
      -high_severity(alert),
      -new_service_in_next_two_weeks(alert),
      -happening_now_key(alert),
      -new_info_in_last_two_weeks(alert),
      effect_index(alert),
      alert.id
    }
  end

  def to_priority_map(alert, stop_id) do
    %{
      specificity: specificity(alert, stop_id),
      high_severity: -high_severity(alert),
      effect_index: effect_index(alert.effect),
      alert_id: alert.id,
      new_service: -new_service_in_next_two_weeks(alert),
      new_info: -new_info_in_last_two_weeks(alert),
      happening_now: -happening_now_key(alert)
    }
  end

  # SPECIFICITY
  # 0 if current stop
  # 1 if whole route
  # 2 if a different specific stop
  # 3 if no stop or route IE
  def specificity(%{informed_entities: ies}, stop_id) do
    ies
    |> Enum.map(&ie_specificity(&1, stop_id))
    |> Enum.min()
  end

  def ie_specificity(ie, stop_id) do
    case ie_target(ie) do
      {:stop, target_stop_id} ->
        if target_stop_id == stop_id, do: 0, else: 2

      {:route, _route_id} ->
        1

      :other ->
        3
    end
  end

  def ie_target(%{stop: stop_id}) do
    {:stop, stop_id}
  end

  def ie_target(%{route: route_id}) do
    {:route, route_id}
  end

  def ie_target(_) do
    :other
  end

  # HIGH SEVERITY
  # severity >= 7
  # Note that we differentiate among severities which are at least 7 (same as dotcom)
  def high_severity(%{severity: severity}) when severity >= 7 do
    severity
  end

  def high_severity(_), do: 0

  def high_severity?(alert) do
    high_severity(alert) > 0
  end

  # HAPPENING NOW
  # defined as: some active period contains the current time
  defp happening_now_key(alert) do
    if happening_now?(alert), do: 1, else: 0
  end

  def happening_now?(%{active_period: aps}, now \\ DateTime.utc_now()) do
    Enum.any?(aps, &in_active_period(&1, now))
  end

  def in_active_period({nil, end_t}, t) do
    DateTime.compare(t, end_t) in [:lt, :eq]
  end

  def in_active_period({start_t, nil}, t) do
    DateTime.compare(t, start_t) in [:gt, :eq]
  end

  def in_active_period({start_t, end_t}, t) do
    DateTime.compare(t, start_t) in [:gt, :eq] && DateTime.compare(t, end_t) in [:lt, :eq]
  end

  def within_two_weeks(time_1, time_2) do
    diff = DateTime.diff(time_1, time_2, :second)
    diff <= 14 * 24 * 60 * 60 && diff >= -14 * 24 * 60 * 60
  end

  # NEW INFO
  # defined as: created_at or updated_at is within the last two weeks
  def new_info_in_last_two_weeks(
        %{created_at: created_at, updated_at: updated_at},
        now \\ DateTime.utc_now()
      ) do
    new_info = within_two_weeks(now, created_at) || within_two_weeks(now, updated_at)
    if new_info, do: 1, else: 0
  end

  # NEW SERVICE
  # defined as: next active_period start in the future is within two weeks of now
  def new_service_in_next_two_weeks(%{active_period: active_period}, now \\ DateTime.utc_now()) do
    next_t = first_future_active_period_start(active_period, now)

    case next_t do
      :infinity ->
        0

      _ ->
        soon =
          next_t
          |> DateTime.from_unix!()
          |> within_two_weeks(now)

        if soon, do: 1, else: 0
    end
  end

  # (from dotcom)
  # atoms are greater than any integer
  defp first_future_active_period_start([], _now), do: :infinity

  defp first_future_active_period_start(periods, now) do
    now_unix = DateTime.to_unix(now, :second)

    future_periods =
      for {start, _} <- periods,
          start,
          # wrap in a list to avoid an Erlang 19.3 issue
          unix <- [DateTime.to_unix(start)],
          unix > now_unix do
        unix
      end

    if future_periods == [] do
      :infinity
    else
      Enum.min(future_periods)
    end
  end

  for {name, index} <- Enum.with_index(@effect_order) do
    defp effect_index(unquote(name)), do: unquote(index)
  end

  # fallback
  defp effect_index(_), do: unquote(length(@effect_order))

  ###

  def by_stop_id(stop_id) do
    {inline_alerts, global_alerts} =
      [stop_id: stop_id]
      |> fetch_or_empty_list()
      |> Enum.split_with(&is_inline?/1)

    global_alert = Enum.min_by(global_alerts, &sort_key(&1, stop_id), fn -> nil end)

    {inline_alerts, global_alert}
  end

  defp is_inline?(%{effect: :delay}) do
    true
  end

  defp is_inline?(_) do
    false
  end

  def build_delay_map(alerts) do
    Enum.reduce(alerts, %{}, &delay_map_reducer/2)
  end

  defp delay_map_reducer(%{informed_entities: ies, severity: severity}, delay_map) do
    route_ids = bus_route_informed_entities(ies)
    Enum.reduce(route_ids, delay_map, &delay_map_reducer_helper(&1, severity, &2))
  end

  defp delay_map_reducer_helper(route_id, severity, delay_map) do
    case delay_map do
      %{^route_id => current_severity} when current_severity >= severity ->
        delay_map

      _ ->
        Map.put(delay_map, route_id, severity)
    end
  end

  defp bus_route_informed_entities(informed_entities) do
    Enum.flat_map(informed_entities, &bus_route_informed_entity/1)
  end

  defp bus_route_informed_entity(%{route: route_id, route_type: 3}) do
    [route_id]
  end

  defp bus_route_informed_entity(_) do
    []
  end

  ###
  def by_route_id(route_id, stop_id) do
    {inline_alerts, global_alerts} =
      [route_id: route_id]
      |> fetch_or_empty_list()
      |> Enum.split_with(&is_inline?/1)

    global_alert = Enum.min_by(global_alerts, &sort_key(&1, stop_id), fn -> nil end)

    {inline_alerts, global_alert}
  end

  def priority_by_route_id(route_id, stop_id) do
    [route_id: route_id]
    |> fetch_or_empty_list()
    |> sort(stop_id)
    |> Enum.map(fn alert ->
      %{alert: to_full_map(alert), priority: to_priority_map(alert, stop_id)}
    end)
  end

  # information -> 1
  # up to 10 minutes -> 3
  # up to 15 minutes -> 4
  # up to 20 minutes -> 5
  # up to 25 minutes -> 6
  # up to 30 minutes -> 7
  # more than 30 minutes -> 8
  # more than an hour -> 9
  # High priority (deliver to T-Alert subscribers immediately) -> 10
  def interpret_severity(severity) do
    cond do
      severity < 3 -> {:up_to, 10}
      severity > 9 -> {:more_than, 60}
      severity >= 8 -> {:more_than, 30 * (severity - 7)}
      true -> {:up_to, 5 * (severity - 1)}
    end
  end
end
