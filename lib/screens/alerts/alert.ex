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

  @type t :: %__MODULE__{
          id: String.t(),
          cause: cause() | :unknown,
          effect: effect() | :unknown,
          severity: integer,
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
          fields: [String.t()],
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
    Screens.Telemetry.span([:screens, :alerts, :alert, :fetch], fn ->
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
          {:ok,
           response
           |> V3Api.Parser.parse()
           |> normalize_informed_entities_for_direction_id()}

        _ ->
          :error
      end
    end)
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

  @alert_cause_mapping %{
    accident: "an accident",
    construction: "construction",
    disabled_train: "a disabled train",
    fire: "a fire",
    holiday: "the holiday",
    maintenance: "maintenance",
    medical_emergency: "a medical emergency",
    police_action: "police action",
    power_problem: "a power issue",
    signal_problem: "a signal problem",
    snow: "snow conditions",
    special_event: "a special event",
    switch_problem: "a switch problem",
    track_problem: "a track problem",
    traffic: "traffic",
    weather: "weather conditions"
  }

  for {cause, cause_text} <- @alert_cause_mapping do
    def get_cause_string(unquote(cause)) do
      "due to #{unquote(cause_text)}"
    end
  end

  def get_cause_string(_), do: ""

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

  @doc "Returns IDs of all subway routes affected by the alert. Green Line routes are not consolidated."
  def informed_subway_routes(%__MODULE__{} = alert) do
    informed_route_ids = MapSet.new(alert.informed_entities, & &1.route)

    Enum.filter(
      ["Blue", "Orange", "Red", "Green-B", "Green-C", "Green-D", "Green-E"],
      &(&1 in informed_route_ids)
    )
  end

  def direction_id(%__MODULE__{informed_entities: informed_entities}),
    do: List.first(informed_entities).direction_id

  def informed_parent_stations(%__MODULE__{
        informed_entities: informed_entities
      }) do
    Enum.filter(informed_entities, &InformedEntity.parent_station?/1)
  end

  # Although Alerts UI allows you to create partial closures affecting multiple stations,
  # we are assuming that will never happen.
  @spec partial_station_closure?(__MODULE__.t(), list(Stop.t())) :: boolean()
  def partial_station_closure?(
        %__MODULE__{effect: :station_closure, informed_entities: informed_entities} = alert,
        all_platforms_at_informed_station
      ) do
    informed_parent_stations = informed_parent_stations(alert)

    case informed_parent_stations do
      [_] ->
        platform_ids = Enum.map(all_platforms_at_informed_station, & &1.id)
        informed_platforms = Enum.filter(informed_entities, &(&1.stop in platform_ids))
        length(informed_platforms) != length(all_platforms_at_informed_station)

      _ ->
        false
    end
  end

  def partial_station_closure?(_, _), do: false

  @spec informs_stop_id?(t(), Stop.id()) :: boolean()
  def informs_stop_id?(%__MODULE__{informed_entities: informed_entities}, stop_id) do
    Enum.any?(informed_entities, &(&1.stop == stop_id))
  end

  @spec normalize_informed_entities_for_direction_id([t()]) :: [t()]
  defp normalize_informed_entities_for_direction_id(alerts) do
    Enum.map(alerts, fn alert ->
      %__MODULE__{
        alert
        | informed_entities:
            alert.informed_entities
            |> Enum.reduce(%{}, fn entity, acc ->
              key = Map.drop(entity, [:direction_id])

              if entity.direction_id == nil do
                Map.put(acc, key, entity)
              else
                case Map.fetch(acc, key) do
                  :error ->
                    Map.put(acc, key, entity)

                  {:ok, matching_entity} ->
                    if matching_entity.direction_id != nil and
                         matching_entity.direction_id == 1 - entity.direction_id do
                      Map.put(acc, key, %{entity | direction_id: nil})
                    else
                      acc
                    end
                end
              end
            end)
            |> Map.values()
      }
    end)
  end
end
