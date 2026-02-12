defmodule Screens.Alerts.Alert do
  @moduledoc false

  alias Screens.Alerts.InformedEntity
  alias Screens.Facilities.Facility
  alias Screens.Routes.Route
  alias Screens.RouteType
  alias Screens.Stops.Stop
  alias Screens.Trips.Trip
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

  @type activity ::
          :board
          | :bringing_bike
          | :exit
          | :park_car
          | :ride
          | :store_bike
          | :using_escalator
          | :using_wheelchair

  @type cause ::
          :accident
          | :amtrak_train_traffic
          | :coast_guard_restriction
          | :construction
          | :crossing_issue
          | :demonstration
          | :disabled_bus
          | :disabled_train
          | :drawbridge_being_raised
          | :electrical_work
          | :fire
          | :fire_department_activity
          | :flooding
          | :fog
          | :freight_train_interference
          | :hazmat_condition
          | :heavy_ridership
          | :high_winds
          | :holiday
          | :hurricane
          | :ice_in_harbor
          | :maintenance
          | :mechanical_issue
          | :mechanical_problem
          | :medical_emergency
          | :parade
          | :police_action
          | :police_activity
          | :power_problem
          | :rail_defect
          | :severe_weather
          | :signal_issue
          | :signal_problem
          | :single_tracking
          | :slippery_rail
          | :snow
          | :special_event
          | :speed_restriction
          | :switch_issue
          | :switch_problem
          | :tie_replacement
          | :track_problem
          | :track_work
          | :traffic
          | :train_traffic
          | :unruly_passenger
          | :weather

  @type effect ::
          :access_issue
          | :additional_service
          | :amber_alert
          | :bike_issue
          | :cancellation
          | :delay
          | :detour
          | :dock_closure
          | :dock_issue
          | :elevator_closure
          | :escalator_closure
          | :extra_service
          | :facility_issue
          | :modified_service
          | :no_service
          | :parking_closure
          | :parking_issue
          | :policy_change
          | :schedule_change
          | :service_change
          | :shuttle
          | :snow_route
          | :station_closure
          | :station_issue
          | :stop_closure
          | :stop_move
          | :stop_moved
          | :summary
          | :suspension
          | :track_change

  @type active_period :: {DateTime.t(), DateTime.t() | nil}

  @type informed_entity :: %{
          activities: nonempty_list(activity()),
          direction_id: Trip.direction() | nil,
          facility: Facility.t() | nil,
          route: Route.id() | nil,
          route_type: non_neg_integer() | nil,
          stop: Stop.id() | nil
        }

  @type id :: String.t()

  @type t :: %__MODULE__{
          id: id(),
          cause: cause() | :unknown,
          effect: effect() | :unknown,
          severity: non_neg_integer(),
          header: String.t(),
          informed_entities: list(informed_entity()),
          active_period: list(active_period()),
          lifecycle: String.t(),
          timeframe: String.t(),
          created_at: DateTime.t(),
          updated_at: DateTime.t(),
          description: String.t()
        }

  @type options :: [
          activities: [activity()] | :all,
          ids: [id()],
          include_all?: boolean(),
          route_id: Route.id(),
          route_ids: [Route.id()],
          route_types: RouteType.t() | [RouteType.t()],
          stop_id: Stop.id(),
          stop_ids: [Stop.id()]
        ]

  @type result :: {:ok, [t()]} | :error
  @type fetch :: (options() -> result())

  @base_includes ~w[facilities]
  @all_includes ~w[facilities.stop.child_stops facilities.stop.parent_station.child_stops]

  @callback fetch(options()) :: result()
  def fetch(opts \\ [], get_json_fn \\ &V3Api.get_json/2) do
    includes =
      if Keyword.get(opts, :include_all?, false),
        do: @all_includes,
        else: @base_includes

    params =
      opts
      |> Enum.flat_map(&format_query_param/1)
      |> Map.new()
      |> Map.put("include", Enum.join(includes, ","))

    case get_json_fn.("alerts", params) do
      {:ok, response} ->
        {:ok, response |> V3Api.Parser.parse() |> Enum.map(&normalize_informed_entities/1)}

      _ ->
        :error
    end
  end

  @doc """
  Convenience for cases when it's safe to treat an API alert data outage
  as if there simply aren't any alerts for the given parameters.

  If the query fails for any reason, an empty list is returned.

  Currently used for DUPs
  """
  @spec fetch_or_empty_list(keyword()) :: list(t())
  def fetch_or_empty_list(opts \\ []) do
    case fetch(opts) do
      {:ok, alerts} -> alerts
      :error -> []
    end
  end

  @doc """
  Used by V2 e-ink and bus shelter alerts

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
  @spec fetch_by_stop_and_route(list(Stop.id()), list(Route.id())) :: {:ok, list(t())} | :error
  def fetch_by_stop_and_route(stop_ids, route_ids, get_json_fn \\ &V3Api.get_json/2) do
    with {:ok, stop_based_alerts} <-
           fetch([stop_ids: stop_ids, route_ids: route_ids], get_json_fn),
         {:ok, route_based_alerts} <- fetch([route_ids: route_ids], get_json_fn) do
      merged_alerts =
        [stop_based_alerts, route_based_alerts]
        |> Enum.concat()
        |> Enum.uniq_by(& &1.id)

      {:ok, merged_alerts}
    else
      :error -> :error
    end
  end

  defp format_query_param({:ids, ids}) when is_list(ids) do
    [{"filter[id]", Enum.join(ids, ",")}]
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

  defp format_query_param({:route_types, route_types}) when is_list(route_types) do
    [
      {"filter[route_type]", Enum.map_join(route_types, ",", &RouteType.to_id/1)}
    ]
  end

  defp format_query_param({:route_types, route_type}) do
    format_query_param({:route_types, [route_type]})
  end

  defp format_query_param({:activities, :all}), do: [{"activity", "ALL"}]

  defp format_query_param({:activities, activities}) when is_list(activities) do
    [
      {
        "activity",
        Enum.map_join(activities, ",", fn value -> value |> to_string() |> String.upcase() end)
      }
    ]
  end

  defp format_query_param(_), do: []

  def happening_now?(%{active_period: aps}, now \\ DateTime.utc_now()) do
    Enum.any?(aps, &in_active_period(&1, now))
  end

  defp in_active_period({start_t, nil}, t) do
    DateTime.compare(t, start_t) in [:gt, :eq]
  end

  defp in_active_period({start_t, end_t}, t) do
    DateTime.compare(t, start_t) in [:gt, :eq] && DateTime.compare(t, end_t) in [:lt, :eq]
  end

  # Rules for grammatically describing alert causes.
  @cause_description_rules %{
    accident: :an,
    amtrak_train_traffic: nil,
    coast_guard_restriction: :a,
    construction: nil,
    crossing_issue: :a,
    demonstration: :a,
    disabled_bus: :a,
    disabled_train: :a,
    drawbridge_being_raised: :a,
    electrical_work: nil,
    fire: :a,
    fire_department_activity: nil,
    flooding: nil,
    fog: nil,
    freight_train_interference: nil,
    hazmat_condition: :a,
    heavy_ridership: nil,
    high_winds: nil,
    holiday: :the,
    hurricane: nil,
    ice_in_harbor: "ice in the harbor",
    maintenance: nil,
    mechanical_issue: :a,
    mechanical_problem: :a,
    medical_emergency: :a,
    parade: :a,
    police_action: nil,
    police_activity: nil,
    power_problem: :a,
    rail_defect: :a,
    severe_weather: nil,
    signal_issue: :a,
    signal_problem: :a,
    single_tracking: nil,
    slippery_rail: nil,
    snow: "snow conditions",
    special_event: :a,
    speed_restriction: :a,
    switch_issue: :a,
    switch_problem: :a,
    tie_replacement: nil,
    track_problem: :a,
    track_work: nil,
    traffic: nil,
    train_traffic: nil,
    unruly_passenger: :an,
    weather: "weather conditions"
  }

  @doc """
  Describes the cause of an alert, e.g. "a signal problem". Returns empty string when the cause is
  unknown.
  """
  @spec cause_description(t()) :: String.t()
  def cause_description(%__MODULE__{cause: :unknown}), do: ""

  def cause_description(%__MODULE__{cause: cause}) do
    case Map.get(@cause_description_rules, cause) do
      nil -> stringify_cause(cause)
      prefix when is_atom(prefix) -> "#{prefix} #{stringify_cause(cause)}"
      other when is_binary(other) -> other
    end
  end

  defp stringify_cause(cause), do: cause |> to_string() |> String.replace("_", " ")

  @doc """
  Describes the impact of an alert on trip times. Mirrors how severity values are labeled in the
  UI used to create alerts. Returns empty string when there is no expected delay ("informational"
  alerts).
  """
  @spec delay_description(t()) :: String.t()
  def delay_description(%__MODULE__{severity: sev}) when sev <= 1, do: ""
  # 2 currently cannot be selected, but is a technically allowed value
  def delay_description(%__MODULE__{severity: sev}) when sev in 2..3, do: "up to 10 minutes"
  def delay_description(%__MODULE__{severity: 4}), do: "up to 15 minutes"
  def delay_description(%__MODULE__{severity: 5}), do: "up to 20 minutes"
  def delay_description(%__MODULE__{severity: 6}), do: "up to 25 minutes"
  def delay_description(%__MODULE__{severity: 7}), do: "up to 30 minutes"
  def delay_description(%__MODULE__{severity: 8}), do: "over 30 minutes"
  # 10 is essentially a signal for urgent notification delivery; its label does not describe any
  # particular impact on trip times. Use the same description for it as 9.
  def delay_description(%__MODULE__{severity: sev}) when sev >= 9, do: "over 60 minutes"

  @doc "Returns IDs of all subway routes affected by the alert. Green Line routes are not consolidated."
  def informed_subway_routes(%__MODULE__{} = alert) do
    informed_route_ids = MapSet.new(alert.informed_entities, & &1.route)

    Enum.filter(
      ["Blue", "Orange", "Red", "Green-B", "Green-C", "Green-D", "Green-E", "Mattapan"],
      &(&1 in informed_route_ids)
    )
  end

  @doc """
  Very imperfectly determine whether an alert only affects one direction of service. Assumes this
  is the case if the alert affects a whole direction of some route, or it affects parent stations
  all in the same direction.
  """
  @spec direction_id(t()) :: Trip.direction() | nil
  def direction_id(%__MODULE__{informed_entities: entities}) do
    direction_from_whole_direction_entities =
      Enum.find_value(entities, fn %{direction_id: direction_id} = entity ->
        if InformedEntity.whole_direction?(entity), do: direction_id
      end)

    direction_from_parent_station_entities =
      case entities
           |> Enum.filter(&InformedEntity.parent_station?/1)
           |> Enum.map(& &1.direction_id)
           |> Enum.uniq() do
        [direction_id] when not is_nil(direction_id) -> direction_id
        _other -> nil
      end

    direction_from_whole_direction_entities || direction_from_parent_station_entities
  end

  def informed_parent_stations(%__MODULE__{
        informed_entities: informed_entities
      }) do
    informed_entities
    |> Enum.filter(&InformedEntity.parent_station?/1)
    |> Enum.uniq_by(& &1.stop)
  end

  @spec station_closure_type(__MODULE__.t(), list(Stop.t())) ::
          :partial_closure | :full_station_closure | :partial_closure_multiple_stops
  def station_closure_type(
        %__MODULE__{effect: :station_closure, informed_entities: informed_entities} = alert,
        platforms_at_informed_stations
      ) do
    # Alerts UI allows you to create partial closures affecting multiple stations.
    # Typically, these partial closures affecting child stops will only affect a single station.
    # However, we do want to consider the case in which multiple stations have closures,
    # but not every child stop at those parent stations are closed.

    informed_parent_stations = informed_parent_stations(alert)

    platforms_affected_by_alert =
      informed_platforms_from_entities(informed_entities, platforms_at_informed_stations)

    case informed_parent_stations do
      [_single_parent_station] ->
        # Compare number of platforms in alert to total number of child platforms at station
        if length(platforms_affected_by_alert) != length(platforms_at_informed_stations) do
          :partial_closure
        else
          :full_station_closure
        end

      _multiple_parent_stations ->
        if length(platforms_affected_by_alert) != length(platforms_at_informed_stations) do
          :partial_closure_multiple_stops
        else
          :full_station_closure
        end
    end
  end

  @spec informed_platforms_from_entities([InformedEntity.t()], [Stop.t()]) :: [InformedEntity.t()]
  def informed_platforms_from_entities(informed_entities, all_platforms_at_informed_stations) do
    platform_ids = Enum.map(all_platforms_at_informed_stations, & &1.id)

    informed_entities
    |> Enum.filter(&(&1.stop in platform_ids))
    |> Enum.uniq_by(& &1.stop)
  end

  @spec informs_stop_id?(t(), Stop.id()) :: boolean()
  def informs_stop_id?(%__MODULE__{informed_entities: informed_entities}, stop_id) do
    Enum.any?(informed_entities, &(&1.stop == stop_id))
  end

  @spec normalize_informed_entities(t()) :: t()
  defp normalize_informed_entities(%__MODULE__{informed_entities: entities} = alert) do
    %__MODULE__{alert | informed_entities: do_normalize_informed_entities(entities)}
  end

  defp do_normalize_informed_entities(entities) do
    entities
    |> Enum.group_by(&Map.put(&1, :direction_id, nil))
    |> Enum.map(fn
      {_directionless_entity, [entity]} -> entity
      {directionless_entity, _multiple} -> directionless_entity
    end)
  end
end
