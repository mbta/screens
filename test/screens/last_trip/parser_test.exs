defmodule Screens.LastTrip.ParserTest do
  use ExUnit.Case, async: true

  alias Screens.LastTrip.Parser

  @trip_updates "test/fixtures/TripUpdates_enhanced.json"
                |> File.read!()
                |> Jason.decode!()

  @vehicle_positions "test/fixtures/VehiclePositions_enhanced.json"
                     |> File.read!()
                     |> Jason.decode!()

  describe "get_running_trips/1" do
    test "returns trip_updates where schedule_relationship is not CANCELED" do
      assert [
               %{"trip" => %{"trip_id" => "scheduled-trip-1"}},
               %{"trip" => %{"trip_id" => "scheduled-trip-2"}},
               %{"trip" => %{"trip_id" => "last-trip-1"}}
             ] =
               Parser.get_running_trips(@trip_updates)
    end
  end

  describe "get_last_trips/1" do
    test "returns trip_ids where last_trip is true" do
      assert ["last-trip-1"] = Parser.get_last_trips(@trip_updates)
    end
  end

  describe "get_recent_departures/2" do
    test "returns all of the recent departures" do
      assert %{{"66", 1, "1304"} => [{"last-trip-1", 1_726_675_388}]} ==
               Parser.get_recent_departures(@trip_updates, @vehicle_positions)
    end
  end
end
