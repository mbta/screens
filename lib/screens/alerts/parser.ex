defmodule Screens.Alerts.Parser do
  @moduledoc false

  def parse_result(%{"data" => data}) when is_list(data) do
    data
    |> Enum.map(&parse_alert/1)
    |> Enum.reject(&is_nil/1)
  end

  def parse_alert(%{"id" => id, "attributes" => attributes}) do
    case attributes do
      %{
        "active_period" => active_period,
        "created_at" => created_at,
        "updated_at" => updated_at,
        "cause" => cause,
        "effect" => effect,
        "header" => header,
        "informed_entity" => informed_entities,
        "lifecycle" => lifecycle,
        "severity" => severity,
        "timeframe" => timeframe,
        "url" => url
      } ->
        %Screens.Alerts.Alert{
          id: id,
          cause: parse_cause(cause),
          effect: parse_effect(effect),
          severity: severity,
          header: header,
          informed_entities: parse_informed_entities(informed_entities),
          active_period: parse_and_sort_active_periods(active_period),
          lifecycle: lifecycle,
          timeframe: timeframe,
          created_at: parse_time(created_at),
          updated_at: parse_time(updated_at),
          url: url
        }

      _ ->
        nil
    end
  end

  defp parse_informed_entities(ies) do
    Enum.map(ies, &parse_informed_entity/1)
  end

  defp parse_informed_entity(ie) do
    %{
      stop: get_in(ie, ["stop"]),
      route: get_in(ie, ["route"]),
      route_type: get_in(ie, ["route_type"]),
      direction_id: get_in(ie, ["direction_id"])
    }
  end

  defp parse_and_sort_active_periods(periods) do
    periods
    |> Enum.map(&parse_active_period/1)
    |> Enum.sort_by(fn {start, _} -> start end, fn dt1, dt2 ->
      DateTime.compare(dt1, dt2) in [:lt, :eq]
    end)
  end

  defp parse_active_period(%{"start" => nil, "end" => end_str}) do
    end_t = parse_time(end_str)
    {nil, end_t}
  end

  defp parse_active_period(%{"start" => start_str, "end" => nil}) do
    start_t = parse_time(start_str)
    {start_t, nil}
  end

  defp parse_active_period(%{"start" => start_str, "end" => end_str}) do
    start_t = parse_time(start_str)
    end_t = parse_time(end_str)
    {start_t, end_t}
  end

  defp parse_time(nil), do: nil

  defp parse_time(s) do
    {:ok, time, _} = DateTime.from_iso8601(s)
    time
  end

  defp parse_effect("AMBER_ALERT"), do: :amber_alert
  defp parse_effect("CANCELLATION"), do: :cancellation
  defp parse_effect("DELAY"), do: :delay
  defp parse_effect("SUSPENSION"), do: :suspension
  defp parse_effect("TRACK_CHANGE"), do: :track_change
  defp parse_effect("DETOUR"), do: :detour
  defp parse_effect("SHUTTLE"), do: :shuttle
  defp parse_effect("STOP_CLOSURE"), do: :stop_closure
  defp parse_effect("DOCK_CLOSURE"), do: :dock_closure
  defp parse_effect("STATION_CLOSURE"), do: :station_closure
  defp parse_effect("STOP_MOVE"), do: :stop_moved
  defp parse_effect("STOP_MOVED"), do: :stop_moved
  defp parse_effect("EXTRA_SERVICE"), do: :extra_service
  defp parse_effect("SCHEDULE_CHANGE"), do: :schedule_change
  defp parse_effect("SERVICE_CHANGE"), do: :service_change
  defp parse_effect("SNOW_ROUTE"), do: :snow_route
  defp parse_effect("STATION_ISSUE"), do: :station_issue
  defp parse_effect("DOCK_ISSUE"), do: :dock_issue
  defp parse_effect("ACCESS_ISSUE"), do: :access_issue
  defp parse_effect("FACILITY_ISSUE"), do: :facility_issue
  defp parse_effect("BIKE_ISSUE"), do: :bike_issue
  defp parse_effect("PARKING_ISSUE"), do: :parking_issue
  defp parse_effect("PARKING_CLOSURE"), do: :parking_closure
  defp parse_effect("ELEVATOR_CLOSURE"), do: :elevator_closure
  defp parse_effect("ESCALATOR_CLOSURE"), do: :escalator_closure
  defp parse_effect("POLICY_CHANGE"), do: :policy_change
  defp parse_effect("STOP_SHOVELING"), do: :stop_shoveling
  defp parse_effect("SUMMARY"), do: :summary
  defp parse_effect(_), do: :unknown

  @causes %{
    "ACCIDENT" => :accident,
    "AMTRAK" => :amtrak,
    "AN_EARLIER_MECHANICAL_PROBLEM" => :an_earlier_mechanical_problem,
    "AN_EARLIER_SIGNAL_PROBLEM" => :an_earlier_signal_problem,
    "AUTOS_IMPEDING_SERVICE" => :autos_impeding_service,
    "COAST_GUARD_RESTRICTION" => :coast_guard_restriction,
    "CONGESTION" => :congestion,
    "CONSTRUCTION" => :construction,
    "CROSSING_MALFUNCTION" => :crossing_malfunction,
    "DEMONSTRATION" => :demonstration,
    "DISABLED_BUS" => :disabled_bus,
    "DISABLED_TRAIN" => :disabled_train,
    "DRAWBRIDGE_BEING_RAISED" => :drawbridge_being_raised,
    "ELECTRICAL_WORK" => :electrical_work,
    "FIRE" => :fire,
    "FOG" => :fog,
    "FREIGHT_TRAIN_INTERFERENCE" => :freight_train_interference,
    "HAZMAT_CONDITION" => :hazmat_condition,
    "HEAVY_RIDERSHIP" => :heavy_ridership,
    "HIGH_WINDS" => :high_winds,
    "HOLIDAY" => :holiday,
    "HURRICANE" => :hurricane,
    "ICE_IN_HARBOR" => :ice_in_harbor,
    "MAINTENANCE" => :maintenance,
    "MECHANICAL_PROBLEM" => :mechanical_problem,
    "MEDICAL_EMERGENCY" => :medical_emergency,
    "PARADE" => :parade,
    "POLICE_ACTION" => :police_action,
    "POWER_PROBLEM" => :power_problem,
    "SEVERE_WEATHER" => :severe_weather,
    "SIGNAL_PROBLEM" => :signal_problem,
    "SLIPPERY_RAIL" => :slippery_rail,
    "SNOW" => :snow,
    "SPECIAL_EVENT" => :special_event,
    "SPEED_RESTRICTION" => :speed_restriction,
    "SWITCH_PROBLEM" => :switch_problem,
    "TIE_REPLACEMENT" => :tie_replacement,
    "TRACK_PROBLEM" => :track_problem,
    "TRACK_WORK" => :track_work,
    "TRAFFIC" => :traffic,
    "UNRULY_PASSENGER" => :unruly_passenger,
    "WEATHER" => :weather
  }

  defp parse_cause(cause) do
    Map.get(@causes, cause, :unknown)
  end
end
