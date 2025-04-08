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
    %{
      activities: Enum.map(ie["activities"], &Map.fetch!(@activities, &1)),
      direction_id: ie["direction_id"],
      facility: parse_informed_facility(ie["facility"], included),
      route: ie["route"],
      route_type: ie["route_type"],
      stop: ie["stop"]
    }
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
