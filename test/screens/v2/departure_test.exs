defmodule Screens.V2.DepartureTest do
  use ExUnit.Case, async: true

  alias Screens.Alerts.Alert
  alias Screens.Routes.Route
  alias Screens.Predictions.Prediction
  alias Screens.Schedules.Schedule
  alias Screens.Trips.Trip
  alias Screens.V2.Departure
  alias Screens.Vehicles.Vehicle

  describe "alerts/1" do
    test "returns alerts from prediction when present" do
      prediction = %Prediction{id: "prediction", alerts: [%Alert{id: "1"}, %Alert{id: "2"}]}
      schedule = %Schedule{id: "schedule"}
      departure = %Departure{prediction: prediction, schedule: schedule}

      assert [%Alert{id: "1"}, %Alert{id: "2"}] = Departure.alerts(departure)
    end

    test "returns empty list when no prediction is present" do
      schedule = %Schedule{id: "schedule"}
      departure = %Departure{schedule: schedule}

      assert [] == Departure.alerts(departure)
    end
  end

  describe "crowding_level/1" do
    test "returns relevant crowding levels" do
      trip = %Trip{id: "trip-1", stops: ["1", "2", "3"]}

      vehicle = %Vehicle{
        occupancy_status: :few_seats_available,
        current_status: :in_transit_to,
        trip_id: "trip-1",
        stop_id: "2"
      }

      prediction = %Prediction{trip: trip, vehicle: vehicle}
      schedule = %Schedule{id: "schedule"}
      departure = %Departure{prediction: prediction, schedule: schedule}

      assert 2 == Departure.crowding_level(departure)
    end

    test "returns nil when the vehicle trip is nil" do
      trip = %Trip{id: "trip-1", stops: ["1", "2", "3"]}

      vehicle = %Vehicle{
        occupancy_status: :few_seats_available,
        current_status: :in_transit_to,
        trip_id: nil,
        stop_id: "2"
      }

      prediction = %Prediction{trip: trip, vehicle: vehicle}
      schedule = %Schedule{id: "schedule"}
      departure = %Departure{prediction: prediction, schedule: schedule}

      assert nil == Departure.crowding_level(departure)

      prediction = %{prediction | vehicle: nil}
      departure = %{departure | prediction: prediction}
      assert nil == Departure.crowding_level(departure)
    end

    test "returns nil when the prediction trip is nil" do
      trip = %Trip{id: nil, stops: ["1", "2", "3"]}

      vehicle = %Vehicle{
        occupancy_status: :few_seats_available,
        current_status: :in_transit_to,
        trip_id: "trip-1",
        stop_id: "2"
      }

      prediction = %Prediction{trip: trip, vehicle: vehicle}
      schedule = %Schedule{id: "schedule"}
      departure = %Departure{prediction: prediction, schedule: schedule}

      assert nil == Departure.crowding_level(departure)

      prediction = %{prediction | trip: nil}
      departure = %{departure | prediction: prediction}
      assert nil == Departure.crowding_level(departure)
    end

    test "returns nil when the vehicle and prediction trips differ" do
      trip = %Trip{id: "trip-1", stops: ["1", "2", "3"]}

      vehicle = %Vehicle{
        occupancy_status: :few_seats_available,
        current_status: :in_transit_to,
        trip_id: "trip-2",
        stop_id: "2"
      }

      prediction = %Prediction{trip: trip, vehicle: vehicle}
      schedule = %Schedule{id: "schedule"}
      departure = %Departure{prediction: prediction, schedule: schedule}

      assert nil == Departure.crowding_level(departure)
    end

    test "returns nil when the vehicle is in transit to the first stop" do
      trip = %Trip{id: "trip-1", stops: ["1", "2", "3"]}

      vehicle = %Vehicle{
        occupancy_status: :few_seats_available,
        current_status: :in_transit_to,
        trip_id: "trip-1",
        stop_id: "1"
      }

      prediction = %Prediction{trip: trip, vehicle: vehicle}
      schedule = %Schedule{id: "schedule"}
      departure = %Departure{prediction: prediction, schedule: schedule}

      assert nil == Departure.crowding_level(departure)
    end

    test "returns nil when no prediction is present" do
      schedule = %Schedule{id: "schedule"}
      departure = %Departure{schedule: schedule}

      assert nil == Departure.crowding_level(departure)
    end
  end

  describe "headsign/1" do
    test "returns prediction headsign" do
      prediction = %Prediction{trip: %Trip{headsign: "Jackson"}}
      schedule = %Schedule{trip: %Trip{headsign: "Ruggles"}}
      departure = %Departure{prediction: prediction, schedule: schedule}

      assert "Jackson" == Departure.headsign(departure)
    end

    test "overrides prediction headsign with stop_headsign from schedule" do
      prediction = %Prediction{trip: %Trip{headsign: "Jackson"}}
      schedule = %Schedule{trip: %Trip{headsign: "Ruggles"}, stop_headsign: "Heath St"}
      departure = %Departure{prediction: prediction, schedule: schedule}

      assert "Heath St" == Departure.headsign(departure)
    end

    test "returns schedule headsign when no prediction is present" do
      schedule = %Schedule{trip: %Trip{headsign: "Ruggles"}}
      departure = %Departure{prediction: nil, schedule: schedule}

      assert "Ruggles" == Departure.headsign(departure)
    end

    test "overrides schedule headsign with stop_headsign from schedule" do
      schedule = %Schedule{trip: %Trip{headsign: "Ruggles"}, stop_headsign: "Heath St"}
      departure = %Departure{prediction: nil, schedule: schedule}

      assert "Heath St" == Departure.headsign(departure)
    end
  end

  describe "id/1" do
    test "returns prediction id when present" do
      prediction = %Prediction{id: "prediction-01"}
      schedule = %Schedule{id: "schedule-01"}
      departure = %Departure{prediction: prediction, schedule: schedule}

      assert "prediction-01" == Departure.id(departure)
    end

    test "returns schedule id when no prediction is present" do
      schedule = %Schedule{id: "schedule-01"}
      departure = %Departure{prediction: nil, schedule: schedule}

      assert "schedule-01" == Departure.id(departure)
    end
  end

  describe "route_id/1" do
    test "returns prediction route_id when present" do
      prediction = %Prediction{route: %Route{id: "28"}}
      schedule = %Schedule{route: %Route{id: "1"}}
      departure = %Departure{prediction: prediction, schedule: schedule}

      assert "28" == Departure.route_id(departure)
    end

    test "returns schedule route_id when no prediction is present" do
      schedule = %Schedule{route: %Route{id: "1"}}
      departure = %Departure{prediction: nil, schedule: schedule}

      assert "1" == Departure.route_id(departure)
    end
  end

  describe "route_name/1" do
    test "returns prediction route short_name when present" do
      prediction = %Prediction{route: %Route{id: "34E", type: :bus, short_name: "214/216"}}
      schedule = %Schedule{route: %Route{id: "1", short_name: "1"}}
      departure = %Departure{prediction: prediction, schedule: schedule}

      assert "214/216" == Departure.route_name(departure)
    end

    test "returns schedule route short_name when no prediction is present" do
      schedule = %Schedule{route: %Route{id: "34E", type: :bus, short_name: "214/216"}}
      departure = %Departure{prediction: nil, schedule: schedule}

      assert "214/216" == Departure.route_name(departure)
    end
  end

  describe "route_type/1" do
    test "returns prediction route_type when present" do
      prediction = %Prediction{route: %Route{type: :rail}}
      schedule = %Schedule{route: %Route{type: :subway}}
      departure = %Departure{prediction: prediction, schedule: schedule}

      assert :rail == Departure.route_type(departure)
    end

    test "returns schedule route_type when no prediction is present" do
      schedule = %Schedule{route: %Route{type: :subway}}
      departure = %Departure{prediction: nil, schedule: schedule}

      assert :subway == Departure.route_type(departure)
    end
  end

  describe "scheduled_time/1" do
    test "returns arrival_time from schedule when present" do
      prediction = %Prediction{
        arrival_time: ~U[2020-01-01T00:00:00Z],
        departure_time: ~U[2020-01-01T00:01:00Z]
      }

      schedule = %Schedule{
        arrival_time: ~U[2020-02-01T00:00:00Z],
        departure_time: ~U[2020-02-01T00:01:00Z]
      }

      departure = %Departure{prediction: prediction, schedule: schedule}

      assert ~U[2020-02-01T00:00:00Z] == Departure.scheduled_time(departure)
    end

    test "returns departure_time from schedule when arrival_time is nil" do
      prediction = %Prediction{
        arrival_time: ~U[2020-01-01T00:00:00Z],
        departure_time: ~U[2020-01-01T00:01:00Z]
      }

      schedule = %Schedule{
        arrival_time: nil,
        departure_time: ~U[2020-02-01T00:00:00Z]
      }

      departure = %Departure{prediction: prediction, schedule: schedule}

      assert ~U[2020-02-01T00:00:00Z] == Departure.scheduled_time(departure)
    end
  end

  describe "stop_type/1" do
    test "correctly identifies first_stop from prediction" do
      prediction = %Prediction{
        arrival_time: nil,
        departure_time: ~U[2020-01-01T00:01:00Z]
      }

      schedule = %Schedule{
        arrival_time: ~U[2020-02-01T00:00:00Z],
        departure_time: ~U[2020-02-01T00:01:00Z]
      }

      departure = %Departure{prediction: prediction, schedule: schedule}

      assert :first_stop == Departure.stop_type(departure)
    end

    test "correctly identifies last_stop from prediction" do
      prediction = %Prediction{
        arrival_time: ~U[2020-01-01T00:00:00Z],
        departure_time: nil
      }

      schedule = %Schedule{
        arrival_time: ~U[2020-02-01T00:00:00Z],
        departure_time: ~U[2020-02-01T00:01:00Z]
      }

      departure = %Departure{prediction: prediction, schedule: schedule}

      assert :last_stop == Departure.stop_type(departure)
    end

    test "correctly identifies mid_route_stop from prediction" do
      prediction = %Prediction{
        arrival_time: ~U[2020-01-01T00:00:00Z],
        departure_time: ~U[2020-01-01T00:01:00Z]
      }

      schedule = %Schedule{
        arrival_time: ~U[2020-02-01T00:00:00Z],
        departure_time: nil
      }

      departure = %Departure{prediction: prediction, schedule: schedule}

      assert :mid_route_stop == Departure.stop_type(departure)
    end

    test "correctly identifies first_stop from schedule" do
      schedule = %Schedule{
        arrival_time: nil,
        departure_time: ~U[2020-02-01T00:01:00Z]
      }

      departure = %Departure{prediction: nil, schedule: schedule}

      assert :first_stop == Departure.stop_type(departure)
    end

    test "correctly identifies last_stop from schedule" do
      schedule = %Schedule{
        arrival_time: ~U[2020-02-01T00:00:00Z],
        departure_time: nil
      }

      departure = %Departure{prediction: nil, schedule: schedule}

      assert :last_stop == Departure.stop_type(departure)
    end

    test "correctly identifies mid_route_stop from schedule" do
      schedule = %Schedule{
        arrival_time: ~U[2020-02-01T00:00:00Z],
        departure_time: ~U[2020-02-01T00:01:00Z]
      }

      departure = %Departure{prediction: nil, schedule: schedule}

      assert :mid_route_stop == Departure.stop_type(departure)
    end
  end

  describe "time/1" do
    test "returns arrival_time from prediction when present" do
      prediction = %Prediction{
        arrival_time: ~U[2020-01-01T00:00:00Z],
        departure_time: ~U[2020-01-01T00:01:00Z]
      }

      schedule = %Schedule{
        arrival_time: ~U[2020-02-01T00:00:00Z],
        departure_time: ~U[2020-02-01T00:01:00Z]
      }

      departure = %Departure{prediction: prediction, schedule: schedule}

      assert ~U[2020-01-01T00:00:00Z] == Departure.time(departure)
    end

    test "returns departure_time from prediction when arrival_time is nil" do
      prediction = %Prediction{
        arrival_time: nil,
        departure_time: ~U[2020-01-01T00:00:00Z]
      }

      schedule = %Schedule{
        arrival_time: ~U[2020-02-01T00:00:00Z],
        departure_time: ~U[2020-02-01T00:01:00Z]
      }

      departure = %Departure{prediction: prediction, schedule: schedule}

      assert ~U[2020-01-01T00:00:00Z] == Departure.time(departure)
    end

    test "returns arrival_time from schedule when prediction is nil" do
      schedule = %Schedule{
        arrival_time: ~U[2020-02-01T00:00:00Z],
        departure_time: ~U[2020-02-01T00:01:00Z]
      }

      departure = %Departure{prediction: nil, schedule: schedule}

      assert ~U[2020-02-01T00:00:00Z] == Departure.time(departure)
    end

    test "returns arrival_time from schedule when prediction and departure_time are nil" do
      schedule = %Schedule{
        arrival_time: ~U[2020-02-01T00:00:00Z],
        departure_time: nil
      }

      departure = %Departure{prediction: nil, schedule: schedule}

      assert ~U[2020-02-01T00:00:00Z] == Departure.time(departure)
    end
  end

  describe "track_number/1" do
    test "returns track_number from prediction when present" do
      prediction = %Prediction{track_number: 3}
      schedule = %Schedule{track_number: 7}
      departure = %Departure{prediction: prediction, schedule: schedule}

      assert 3 == Departure.track_number(departure)
    end

    test "returns track_number from schedule when prediction track_number is nil" do
      prediction = %Prediction{track_number: nil}
      schedule = %Schedule{track_number: 7}
      departure = %Departure{prediction: prediction, schedule: schedule}

      assert 7 == Departure.track_number(departure)
    end

    test "returns track_number from schedule when prediction is nil" do
      schedule = %Schedule{track_number: 7}
      departure = %Departure{prediction: nil, schedule: schedule}

      assert 7 == Departure.track_number(departure)
    end
  end

  describe "vehicle_status/1" do
    test "returns vehicle status from prediction when present" do
      prediction = %Prediction{vehicle: %Vehicle{current_status: :in_transit_to}}
      schedule = %Schedule{id: "schedule"}
      departure = %Departure{prediction: prediction, schedule: schedule}

      assert :in_transit_to == Departure.vehicle_status(departure)
    end

    test "returns nil when prediction doesn't have an associated vehicle" do
      prediction = %Prediction{vehicle: nil}
      schedule = %Schedule{id: "schedule"}
      departure = %Departure{prediction: prediction, schedule: schedule}

      assert nil == Departure.vehicle_status(departure)
    end

    test "returns nil when prediction is nil" do
      schedule = %Schedule{id: "schedule"}
      departure = %Departure{prediction: nil, schedule: schedule}

      assert nil == Departure.vehicle_status(departure)
    end
  end
end
