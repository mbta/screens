defmodule Screens.LastTrip.Parser do
  @moduledoc """
  Functions to parse relevant data from TripUpdate and VehiclePositions maps.

  Used by `Screens.LastTrip.Poller`.
  """
  alias Screens.LastTrip.Cache.RecentDepartures

  @spec get_running_trips(trip_updates_enhanced_json :: map()) :: [trip_update_json :: map()]
  def get_running_trips(trip_updates_enhanced_json) do
    trip_updates_enhanced_json["entity"]
    |> Stream.map(& &1["trip_update"])
    |> Enum.reject(&(&1["trip"]["schedule_relationship"] == "CANCELED"))
  end

  @spec get_last_trips(trip_updates_enhanced_json :: map()) :: [trip_id :: String.t()]
  def get_last_trips(trip_updates_enhanced_json) do
    trip_updates_enhanced_json
    |> get_running_trips()
    |> Enum.filter(&(&1["trip"]["last_trip"] == true))
    |> Enum.map(& &1["trip"]["trip_id"])
  end

  @spec get_recent_departures(
          trip_updates_enhanced_json :: map(),
          vehicle_positions_enhanced_json :: map()
        ) :: %{RecentDepartures.key() => RecentDepartures.value()}
  def get_recent_departures(trip_updates_enhanced_json, vehicle_positions_enhanced_json) do
    vehicle_positions_by_id =
      Map.new(vehicle_positions_enhanced_json["entity"], &{&1["id"], &1["vehicle"]})

    running_trips = get_running_trips(trip_updates_enhanced_json)

    for %{"vehicle" => %{"id" => vehicle_id}} = trip <- running_trips,
        stop_time_update <- trip["stop_time_update"] do
      vehicle_position = vehicle_positions_by_id[vehicle_id]

      departure_time = stop_time_update["departure"]["time"]

      if vehicle_position["stop_id"] == stop_time_update["stop_id"] and
           vehicle_position["current_status"] == "STOPPED_AT" and not is_nil(departure_time) do
        rds =
          {trip["trip"]["route_id"], trip["trip"]["direction_id"], stop_time_update["stop_id"]}

        trip_id = trip["trip"]["trip_id"]

        {rds, {trip_id, departure_time}}
      end
    end
    |> Enum.reject(&is_nil/1)
    |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
  end
end
