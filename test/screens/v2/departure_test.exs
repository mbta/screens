defmodule Screens.V2.DepartureTest do
  use ExUnit.Case, async: true

  alias Screens.Alerts.Alert
  alias Screens.Routes.Route
  alias Screens.Predictions.Prediction
  alias Screens.Schedules.Schedule
  alias Screens.Stops.Stop
  alias Screens.Trips.Trip
  alias Screens.Vehicles.Vehicle
  alias Screens.V2.Departure

  describe "get_relevant_departures/1" do
    test "filters out departures with both arrival_time and departure_time nil" do
      d1 = %Prediction{id: "arrival", arrival_time: ~U[2020-02-01T01:00:00Z], departure_time: nil}

      d2 = %Prediction{
        id: "departure",
        arrival_time: nil,
        departure_time: ~U[2020-02-01T01:00:00Z]
      }

      d3 = %Prediction{
        id: "both",
        arrival_time: ~U[2020-02-01T01:00:00Z],
        departure_time: ~U[2020-02-01T01:00:00Z]
      }

      d4 = %Prediction{id: "neither", arrival_time: nil, departure_time: nil}
      departures = [d1, d2, d3, d4]

      now = ~U[2020-01-01T01:00:00Z]

      assert MapSet.new([d1, d2, d3]) ==
               MapSet.new(Departure.get_relevant_departures(departures, now))
    end

    test "filters out departures in the past" do
      d1 = %Schedule{id: "1", arrival_time: ~U[2020-01-01T00:00:00Z]}

      d2 = %Schedule{
        id: "2",
        arrival_time: ~U[2020-01-01T00:00:00Z],
        departure_time: ~U[2020-01-01T02:00:00Z]
      }

      d3 = %Schedule{id: "3", departure_time: ~U[2020-01-01T00:00:00Z]}
      d4 = %Schedule{id: "4", departure_time: ~U[2020-01-01T02:00:00Z]}
      d5 = %Schedule{id: "5", arrival_time: ~U[2020-02-01T00:00:00Z]}
      departures = [d1, d2, d3, d4, d5]

      now = ~U[2020-01-01T01:00:00Z]

      assert MapSet.new([d2, d4, d5]) ==
               MapSet.new(Departure.get_relevant_departures(departures, now))
    end

    test "filters out extra departures for multi-route trips" do
      d1 = %Prediction{
        id: "1",
        trip: %Trip{id: "47610992", route_id: "214216"},
        route: %Route{id: "214"},
        departure_time: ~U[2020-01-01T01:00:00Z]
      }

      d2 = %Prediction{
        id: "2",
        trip: %Trip{id: "47610992", route_id: "214216"},
        route: %Route{id: "216"},
        departure_time: ~U[2020-01-01T01:00:00Z]
      }

      d3 = %Prediction{
        id: "3",
        trip: %Trip{id: "47610992", route_id: "214216"},
        route: %Route{id: "214216"},
        departure_time: ~U[2020-01-01T01:00:00Z]
      }

      d4 = %Prediction{
        id: "4",
        trip: nil,
        route: %Route{id: "214216"},
        departure_time: ~U[2020-01-01T01:00:00Z]
      }

      d5 = %Prediction{
        id: "5",
        trip: %Trip{id: "47610994", route_id: "214216"},
        route: nil,
        departure_time: ~U[2020-01-01T01:00:00Z]
      }

      departures = [d1, d2, d3, d4, d5]

      now = ~U[2020-01-01T00:00:00Z]

      assert MapSet.new([d3, d4, d5]) ==
               MapSet.new(Departure.get_relevant_departures(departures, now))
    end

    test "filters out departures for departed vehicles" do
      d1 = %Prediction{
        id: "1",
        stop: %Stop{id: "2"},
        trip: %Trip{id: "t1", stops: ["1", "2", "3"]},
        vehicle: %Vehicle{trip_id: "t1", stop_id: "3", current_status: :in_transit_to},
        departure_time: ~U[2020-01-01T01:00:00Z]
      }

      d2 = %Prediction{
        id: "2",
        stop: %Stop{id: "2"},
        trip: %Trip{id: "t11", stops: ["1", "2", "3"]},
        vehicle: %Vehicle{trip_id: "t11", stop_id: "2", current_status: :in_transit_to},
        departure_time: ~U[2020-01-01T01:00:00Z]
      }

      d3 = %Prediction{
        id: "3",
        stop: %Stop{id: "2"},
        trip: %Trip{id: "t21", stops: ["3", "2", "1"]},
        vehicle: %Vehicle{trip_id: "t22", stop_id: "1", current_status: :stopped_at},
        departure_time: ~U[2020-01-01T01:00:00Z]
      }

      d4 = %Prediction{
        id: "4",
        stop: %Stop{id: "2"},
        trip: %Trip{id: "t31", stops: []},
        vehicle: %Vehicle{trip_id: "t31", stop_id: "3", current_status: :incoming_at},
        departure_time: ~U[2020-01-01T01:00:00Z]
      }

      d5 = %Prediction{
        id: "5",
        stop: %Stop{id: "2"},
        trip: %Trip{id: "t41", stops: ["1", "2", "3"]},
        vehicle: %Vehicle{trip_id: "t41", stop_id: nil, current_status: :incoming_at},
        departure_time: ~U[2020-01-01T01:00:00Z]
      }

      departures = [d1, d2, d3, d4, d5]
      now = ~U[2020-01-01T00:00:00Z]

      assert MapSet.new([d2, d3, d4, d5]) ==
               MapSet.new(Departure.get_relevant_departures(departures, now))
    end

    test "returns only the earliest departure on each trip" do
      d1 = %Schedule{id: "1", trip: %Trip{id: "t1"}, departure_time: ~U[2020-02-01T00:00:00Z]}
      d2 = %Schedule{id: "2", trip: %Trip{id: "t1"}, departure_time: ~U[2020-02-01T00:01:00Z]}
      d3 = %Schedule{id: "3", trip: %Trip{id: "t2"}, departure_time: ~U[2020-02-01T01:01:00Z]}
      d4 = %Schedule{id: "4", trip: %Trip{id: "t2"}, departure_time: ~U[2020-02-01T01:00:00Z]}
      d5 = %Schedule{id: "5", trip: %Trip{id: nil}, departure_time: ~U[2020-02-01T00:00:00Z]}
      d6 = %Schedule{id: "6", trip: nil, departure_time: ~U[2020-02-01T00:00:00Z]}
      departures = [d1, d2, d3, d4, d5, d6]

      now = ~U[2020-01-01T00:00:00Z]

      assert MapSet.new([d1, d4, d5, d6]) ==
               MapSet.new(Departure.get_relevant_departures(departures, now))
    end
  end

  describe "merge_predictions_and_schedules/2" do
    test "combines predictions and schedules with matching trip_ids" do
      p1 = %Prediction{id: "p1", departure_time: ~U[2020-02-01T00:00:00Z], trip: %Trip{id: "t7"}}
      p2 = %Prediction{id: "p2", departure_time: ~U[2020-02-01T01:00:00Z], trip: %Trip{id: "t3"}}
      predictions = [p1, p2]

      s1 = %Schedule{id: "s1", departure_time: ~U[2020-02-01T01:01:00Z], trip: %Trip{id: "t3"}}
      s2 = %Schedule{id: "s2", departure_time: ~U[2020-02-01T00:01:00Z], trip: %Trip{id: "t7"}}
      schedules = [s1, s2]

      expected = [
        %Departure{prediction: p1, schedule: s2},
        %Departure{prediction: p2, schedule: s1}
      ]

      assert expected == Departure.merge_predictions_and_schedules(predictions, schedules)
    end

    test "returns predictions without matching schedules" do
      p1 = %Prediction{id: "p1", departure_time: ~U[2020-02-01T00:00:00Z], trip: %Trip{id: "t7"}}
      p2 = %Prediction{id: "p2", departure_time: ~U[2020-02-01T01:00:00Z], trip: %Trip{id: "t3"}}
      predictions = [p1, p2]

      s2 = %Schedule{id: "s2", departure_time: ~U[2020-02-01T00:01:00Z], trip: %Trip{id: "t7"}}
      schedules = [s2]

      expected = [
        %Departure{prediction: p1, schedule: s2},
        %Departure{prediction: p2, schedule: nil}
      ]

      assert expected == Departure.merge_predictions_and_schedules(predictions, schedules)
    end

    test "returns schedules without matching predictions" do
      p1 = %Prediction{id: "p1", departure_time: ~U[2020-02-01T00:00:00Z], trip: %Trip{id: "t7"}}
      predictions = [p1]

      s1 = %Schedule{id: "s1", departure_time: ~U[2020-02-01T01:01:00Z], trip: %Trip{id: "t3"}}
      s2 = %Schedule{id: "s2", departure_time: ~U[2020-02-01T00:01:00Z], trip: %Trip{id: "t7"}}
      schedules = [s1, s2]

      expected = [
        %Departure{prediction: p1, schedule: s2},
        %Departure{prediction: nil, schedule: s1}
      ]

      assert expected == Departure.merge_predictions_and_schedules(predictions, schedules)
    end

    test "returns departures in increasing time order" do
      p1 = %Prediction{id: "mid", arrival_time: ~U[2020-02-01T02:00:00Z], trip: %Trip{id: "t1"}}

      p2 = %Prediction{
        id: "earlier",
        arrival_time: ~U[2020-02-01T01:00:00Z],
        departure_time: nil,
        trip: %Trip{id: "t2"}
      }

      p3 = %Prediction{
        id: "latest",
        departure_time: ~U[2020-02-01T03:00:00Z],
        trip: %Trip{id: "t3"}
      }

      predictions = [p1, p2, p3]

      s1 = %Schedule{id: "mid", departure_time: ~U[2020-02-02T02:00:00Z], trip: %Trip{id: "t1"}}

      s2 = %Schedule{
        id: "earliest",
        arrival_time: ~U[2020-02-02T00:00:00Z],
        departure_time: ~U[2020-02-01T00:00:00Z],
        trip: %Trip{id: "t4"}
      }

      schedules = [s1, s2]

      expected = [
        %Departure{prediction: nil, schedule: s2},
        %Departure{prediction: p2, schedule: nil},
        %Departure{prediction: p1, schedule: s1},
        %Departure{prediction: p3, schedule: nil}
      ]

      assert expected == Departure.merge_predictions_and_schedules(predictions, schedules)
    end
  end

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
      prediction = %Prediction{route: %Route{id: "214216", short_name: "214/216"}}
      schedule = %Schedule{route: %Route{id: "1", short_name: "1"}}
      departure = %Departure{prediction: prediction, schedule: schedule}

      assert "214/216" == Departure.route_name(departure)
    end

    test "returns schedule route short_name when no prediction is present" do
      schedule = %Schedule{route: %Route{id: "214216", short_name: "214/216"}}
      departure = %Departure{prediction: nil, schedule: schedule}

      assert "214/216" == Departure.route_name(departure)
    end
  end

  describe "route_type/1" do
    test "returns prediction route_type when present" do
      prediction = %Prediction{route: %Route{type: 2}}
      schedule = %Schedule{route: %Route{type: 1}}
      departure = %Departure{prediction: prediction, schedule: schedule}

      assert 2 == Departure.route_type(departure)
    end

    test "returns schedule route_type when no prediction is present" do
      schedule = %Schedule{route: %Route{type: 1}}
      departure = %Departure{prediction: nil, schedule: schedule}

      assert 1 == Departure.route_type(departure)
    end
  end

  describe "scheduled_time/1" do
    test "returns departure_time from schedule when present" do
      prediction = %Prediction{
        arrival_time: ~U[2020-01-01T00:00:00Z],
        departure_time: ~U[2020-01-01T00:01:00Z]
      }

      schedule = %Schedule{
        arrival_time: ~U[2020-02-01T00:00:00Z],
        departure_time: ~U[2020-02-01T00:01:00Z]
      }

      departure = %Departure{prediction: prediction, schedule: schedule}

      assert ~U[2020-02-01T00:01:00Z] == Departure.scheduled_time(departure)
    end

    test "returns arrival_time from schedule when departure_time is nil" do
      prediction = %Prediction{
        arrival_time: ~U[2020-01-01T00:00:00Z],
        departure_time: ~U[2020-01-01T00:01:00Z]
      }

      schedule = %Schedule{
        arrival_time: ~U[2020-02-01T00:00:00Z],
        departure_time: nil
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
    test "returns departure_time from prediction when present" do
      prediction = %Prediction{
        arrival_time: ~U[2020-01-01T00:00:00Z],
        departure_time: ~U[2020-01-01T00:01:00Z]
      }

      schedule = %Schedule{
        arrival_time: ~U[2020-02-01T00:00:00Z],
        departure_time: ~U[2020-02-01T00:01:00Z]
      }

      departure = %Departure{prediction: prediction, schedule: schedule}

      assert ~U[2020-01-01T00:01:00Z] == Departure.time(departure)
    end

    test "returns arrival_time from prediction when departure_time is nil" do
      prediction = %Prediction{
        arrival_time: ~U[2020-01-01T00:00:00Z],
        departure_time: nil
      }

      schedule = %Schedule{
        arrival_time: ~U[2020-02-01T00:00:00Z],
        departure_time: ~U[2020-02-01T00:01:00Z]
      }

      departure = %Departure{prediction: prediction, schedule: schedule}

      assert ~U[2020-01-01T00:00:00Z] == Departure.time(departure)
    end

    test "returns departure_time from schedule when prediction is nil" do
      schedule = %Schedule{
        arrival_time: ~U[2020-02-01T00:00:00Z],
        departure_time: ~U[2020-02-01T00:01:00Z]
      }

      departure = %Departure{prediction: nil, schedule: schedule}

      assert ~U[2020-02-01T00:01:00Z] == Departure.time(departure)
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
