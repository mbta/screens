defmodule Screens.Alerts.Parser do
  @moduledoc false

  def parse_result(result) do
    result
    |> Map.get("data")
    |> parse_data()
  end

  defp parse_data(data) do
    data
    |> Enum.map(fn item -> parse_alert(item) end)
  end

  def parse_alert(%{"id" => id, "attributes" => attributes}) do
    %{
      "active_period" => active_period,
      "created_at" => created_at,
      "updated_at" => updated_at,
      "effect" => effect,
      "header" => header,
      "informed_entity" => informed_entities,
      "lifecycle" => lifecycle,
      "severity" => severity,
      "timeframe" => timeframe
    } = attributes

    %Screens.Alerts.Alert{
      id: id,
      effect: parse_effect(effect),
      severity: severity,
      header: header,
      informed_entities: informed_entities,
      active_period: parse_active_periods(active_period),
      lifecycle: lifecycle,
      timeframe: timeframe,
      created_at: parse_time(created_at),
      updated_at: parse_time(updated_at)
    }
  end

  defp parse_active_periods(periods) do
    Enum.map(periods, fn p -> parse_active_period(p) end)
  end

  defp parse_active_period(%{"start" => nil, "end" => end_str}) do
    {:ok, end_t, _} = DateTime.from_iso8601(end_str)
    {nil, end_t}
  end

  defp parse_active_period(%{"start" => start_str, "end" => nil}) do
    {:ok, start_t, _} = DateTime.from_iso8601(start_str)
    {start_t, nil}
  end

  defp parse_active_period(%{"start" => start_str, "end" => end_str}) do
    {:ok, start_t, _} = DateTime.from_iso8601(start_str)
    {:ok, end_t, _} = DateTime.from_iso8601(end_str)
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
  # previous configuration
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
end
