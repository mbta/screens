defmodule Screens.Alerts.Parser do
  @moduledoc false

  alias Screens.Alerts.Alert
  alias Screens.V3Api

  def parse(
        %{
          "id" => id,
          "attributes" => %{
            "active_period" => active_period,
            "cause" => cause,
            "created_at" => created_at,
            "description" => description,
            "effect" => effect,
            "header" => header,
            "informed_entity" => informed_entities,
            "lifecycle" => lifecycle,
            "severity" => severity,
            "timeframe" => timeframe,
            "updated_at" => updated_at,
            "url" => url
          }
        },
        included
      ) do
    %Alert{
      id: id,
      active_period: parse_and_sort_active_periods(active_period),
      cause: parse_cause(cause),
      created_at: parse_datetime(created_at),
      description: description,
      effect: parse_effect(effect),
      header: header,
      informed_entities: Enum.map(informed_entities, &parse_informed_entity(&1, included)),
      lifecycle: lifecycle,
      severity: severity,
      timeframe: timeframe,
      updated_at: parse_datetime(updated_at),
      url: url
    }
  end

  @activities %{
    "BOARD" => :board,
    "BRINGING_BIKE" => :bringing_bike,
    "EXIT" => :exit,
    "PARK_CAR" => :park_car,
    "RIDE" => :ride,
    "STORE_BIKE" => :store_bike,
    "USING_ESCALATOR" => :using_escalator,
    "USING_WHEELCHAIR" => :using_wheelchair
  }

  defp parse_informed_entity(ie, included) do
    platform_name = parse_platform_name_from_stop(ie["stop"], included)

    %{
      activities: Enum.map(ie["activities"], &Map.fetch!(@activities, &1)),
      direction_id: ie["direction_id"],
      facility: parse_informed_facility(ie["facility"], included),
      route: ie["route"],
      route_type: ie["route_type"],
      stop: ie["stop"],
      platform_name: platform_name
    }
  end

  defp parse_platform_name_from_stop(nil, _included), do: nil

  defp parse_platform_name_from_stop(stop_id, included) do
    case Map.get(included, {stop_id, "stop"}) do
      nil ->
        nil

      %{"attributes" => %{"platform_name" => platform_name}} ->
        platform_name

      _stop ->
        nil
    end
  end

  defp parse_informed_facility(nil, _included), do: nil

  defp parse_informed_facility(id, included),
    do: V3Api.Parser.included!(%{"data" => %{"id" => id, "type" => "facility"}}, included)

  defp parse_and_sort_active_periods(periods) do
    periods
    |> Enum.map(fn %{"start" => start_str, "end" => end_str} ->
      {parse_datetime(start_str), if(is_nil(end_str), do: nil, else: parse_datetime(end_str))}
    end)
    |> Enum.sort_by(
      fn {start, _} -> start end,
      fn dt1, dt2 -> DateTime.compare(dt1, dt2) in [:lt, :eq] end
    )
  end

  defp parse_datetime(iso_str) do
    {:ok, time, _offset} = DateTime.from_iso8601(iso_str)
    time
  end

  @causes %{
    "ACCIDENT" => :accident,
    "AMTRAK_TRAIN_TRAFFIC" => :amtrak_train_traffic,
    "COAST_GUARD_RESTRICTION" => :coast_guard_restriction,
    "CONSTRUCTION" => :construction,
    "CROSSING_ISSUE" => :crossing_issue,
    "DEMONSTRATION" => :demonstration,
    "DISABLED_BUS" => :disabled_bus,
    "DISABLED_TRAIN" => :disabled_train,
    "DRAWBRIDGE_BEING_RAISED" => :drawbridge_being_raised,
    "ELECTRICAL_WORK" => :electrical_work,
    "FIRE" => :fire,
    "FIRE_DEPARTMENT_ACTIVITY" => :fire_department_activity,
    "FLOODING" => :flooding,
    "FOG" => :fog,
    "FREIGHT_TRAIN_INTERFERENCE" => :freight_train_interference,
    "HAZMAT_CONDITION" => :hazmat_condition,
    "HEAVY_RIDERSHIP" => :heavy_ridership,
    "HIGH_WINDS" => :high_winds,
    "HOLIDAY" => :holiday,
    "HURRICANE" => :hurricane,
    "ICE_IN_HARBOR" => :ice_in_harbor,
    "MAINTENANCE" => :maintenance,
    "MECHANICAL_ISSUE" => :mechanical_issue,
    "MECHANICAL_PROBLEM" => :mechanical_problem,
    "MEDICAL_EMERGENCY" => :medical_emergency,
    "PARADE" => :parade,
    "POLICE_ACTION" => :police_action,
    "POLICE_ACTIVITY" => :police_activity,
    "POWER_PROBLEM" => :power_problem,
    "RAIL_DEFECT" => :rail_defect,
    "SEVERE_WEATHER" => :severe_weather,
    "SIGNAL_ISSUE" => :signal_issue,
    "SIGNAL_PROBLEM" => :signal_problem,
    "SINGLE_TRACKING" => :single_tracking,
    "SLIPPERY_RAIL" => :slippery_rail,
    "SNOW" => :snow,
    "SPECIAL_EVENT" => :special_event,
    "SPEED_RESTRICTION" => :speed_restriction,
    "SWITCH_ISSUE" => :switch_issue,
    "SWITCH_PROBLEM" => :switch_problem,
    "TIE_REPLACEMENT" => :tie_replacement,
    "TRACK_PROBLEM" => :track_problem,
    "TRACK_WORK" => :track_work,
    "TRAFFIC" => :traffic,
    "TRAIN_TRAFFIC" => :train_traffic,
    "UNRULY_PASSENGER" => :unruly_passenger,
    "WEATHER" => :weather
  }

  @effects %{
    "ACCESS_ISSUE" => :access_issue,
    "ADDITIONAL_SERVICE" => :additional_service,
    "AMBER_ALERT" => :amber_alert,
    "BIKE_ISSUE" => :bike_issue,
    "CANCELLATION" => :cancellation,
    "DELAY" => :delay,
    "DETOUR" => :detour,
    "DOCK_CLOSURE" => :dock_closure,
    "DOCK_ISSUE" => :dock_issue,
    "ELEVATOR_CLOSURE" => :elevator_closure,
    "ESCALATOR_CLOSURE" => :escalator_closure,
    "EXTRA_SERVICE" => :extra_service,
    "FACILITY_ISSUE" => :facility_issue,
    "MODIFIED_SERVICE" => :modified_service,
    "NO_SERVICE" => :no_service,
    "OTHER_EFFECT" => :other_effect,
    "PARKING_CLOSURE" => :parking_closure,
    "PARKING_ISSUE" => :parking_issue,
    "POLICY_CHANGE" => :policy_change,
    "SCHEDULE_CHANGE" => :schedule_change,
    "SERVICE_CHANGE" => :service_change,
    "SHUTTLE" => :shuttle,
    "SNOW_ROUTE" => :snow_route,
    "STATION_CLOSURE" => :station_closure,
    "STATION_ISSUE" => :station_issue,
    "STOP_CLOSURE" => :stop_closure,
    "STOP_MOVE" => :stop_move,
    "STOP_MOVED" => :stop_moved,
    "SUMMARY" => :summary,
    "SUSPENSION" => :suspension,
    "TRACK_CHANGE" => :track_change
  }

  defp parse_cause(cause), do: Map.get(@causes, cause, :unknown)
  defp parse_effect(effect), do: Map.get(@effects, effect, :unknown)
end
