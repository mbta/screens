defmodule Screens.V2.DepartureTest do
  use ExUnit.Case, async: true

  alias Screens.Routes.Route
  alias Screens.Predictions.Prediction
  alias Screens.Schedules.Schedule
  alias Screens.Trips.Trip
  alias Screens.V2.Departure
  alias Screens.Vehicles.Vehicle

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

    test "returns nil when the vehicle is at the first stop" do
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

  describe "route/1" do
    test "returns prediction route when present" do
      prediction = %Prediction{route: %Route{id: "28"}}
      schedule = %Schedule{route: %Route{id: "1"}}
      departure = %Departure{prediction: prediction, schedule: schedule}

      assert %Route{id: "28"} == Departure.route(departure)
    end

    test "returns schedule route when no prediction is present" do
      schedule = %Schedule{route: %Route{id: "1"}}
      departure = %Departure{prediction: nil, schedule: schedule}

      assert %Route{id: "1"} == Departure.route(departure)
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

    test "returns time from schedule for a nil/nil prediction" do
      schedule = %Schedule{arrival_time: ~U[2020-02-01T00:00:00Z]}
      prediction = %Prediction{arrival_time: nil, departure_time: nil}
      departure = %Departure{prediction: prediction, schedule: schedule}

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

  describe "fetch/1" do
    test "maintains schedules even if they are in the past" do
      now = ~U[2024-08-28 17:13:14.116713Z]
      # The train is _very_ late!!
      schedule =
        %Schedule{
          trip: %Trip{id: "trip-1"},
          arrival_time: DateTime.add(now, -10, :minute),
          departure_time: DateTime.add(now, -8, :minute)
        }

      # The train is almost here!
      prediction =
        %Prediction{
          trip: %Trip{id: "trip-1"},
          arrival_time: DateTime.add(now, 2, :minute),
          departure_time: DateTime.add(now, 5, :minute)
        }

      fetch_predictions_fn = fn _ -> {:ok, [prediction]} end
      fetch_schedules_fn = fn _ -> {:ok, [schedule]} end

      assert {:ok, [%Departure{schedule: schedule, prediction: prediction}]} ==
               Departure.fetch(
                 %{},
                 now: now,
                 fetch_predictions_fn: fetch_predictions_fn,
                 fetch_schedules_fn: fetch_schedules_fn
               )
    end
  end

  describe "encode_params/1" do
    test "encodes params correctly, including route_type list" do
      params = %{
        direction_id: 1,
        route_ids: ["CR-Fairmount"],
        route_type: [:ferry, :rail],
        stop_ids: ["place-sstat"]
      }

      assert %{
               "filter[direction_id]" => 1,
               "filter[route]" => "CR-Fairmount",
               "filter[route_type]" => "4,2",
               "filter[stop]" => "place-sstat"
             } == Departure.encode_params(params)
    end

    test "encodes params correctly, including single route_type" do
      params = %{
        direction_id: 1,
        route_ids: ["Red"],
        route_type: [:subway],
        stop_ids: ["place-sstat"]
      }

      assert %{
               "filter[direction_id]" => 1,
               "filter[route]" => "Red",
               "filter[route_type]" => "1",
               "filter[stop]" => "place-sstat"
             } == Departure.encode_params(params)
    end
  end

  describe "build_params_for_schedules/2" do
    test "returns params string route_type when no opts is provided" do
      params = %{route_type: :subway}
      opts = []

      result = Departure.build_params_for_schedules(params, opts)

      assert result == %{route_type: [:subway]}
    end

    test "returns params list route_type  when no opts is provided" do
      params = %{route_type: [:light_rail, :subway]}
      opts = []

      result = Departure.build_params_for_schedules(params, opts)

      assert result == params
    end

    test "returns schedule_route_type_filter option when provided" do
      params = %{stop_ids: "place-sstat"}
      opts = [schedule_route_type_filter: [:rail, :ferry]]

      result = Departure.build_params_for_schedules(params, opts)

      assert result == %{route_type: [:rail, :ferry], stop_ids: "place-sstat"}
    end

    test "returns only the intersection of params and opts" do
      params = %{route_type: [:rail, :subway]}
      opts = [schedule_route_type_filter: [:rail, :ferry]]

      result = Departure.build_params_for_schedules(params, opts)

      assert result == %{route_type: [:rail]}
    end

    test "returns empty list when intersection is empty" do
      params = %{route_type: [:subway, :light_rail]}
      opts = [schedule_route_type_filter: [:ferry, :rail]]

      result = Departure.build_params_for_schedules(params, opts)

      assert result == %{route_type: []}
    end

    test "defaults to all route types when :route_type is not in params or options" do
      params = %{}
      opts = []

      result = Departure.build_params_for_schedules(params, opts)

      assert result == %{route_type: [:light_rail, :subway, :rail, :bus, :ferry]}
    end
  end
end
