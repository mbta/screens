defmodule Screens.V2.Departure.BuilderTest do
  use ExUnit.Case, async: true

  alias Screens.Routes.Route
  alias Screens.Predictions.Prediction
  alias Screens.Schedules.Schedule
  alias Screens.Stops.Stop
  alias Screens.Trips.Trip
  alias Screens.Vehicles.Vehicle
  alias Screens.V2.Departure
  alias Screens.V2.Departure.Builder

  describe "build/3" do
    @now ~U[2020-01-01T01:00:00Z]

    defp to_departures(predictions_or_schedules) do
      Enum.map(predictions_or_schedules, fn
        %Prediction{} = p -> %Departure{prediction: p, schedule: nil}
        %Schedule{} = s -> %Departure{prediction: nil, schedule: s}
      end)
    end

    test "filters out departures with both arrival_time and departure_time nil" do
      p1 = %Prediction{id: "arrival", arrival_time: ~U[2020-02-01T01:00:00Z], departure_time: nil}

      p2 = %Prediction{
        id: "departure",
        arrival_time: nil,
        departure_time: ~U[2020-02-01T01:00:00Z]
      }

      p3 = %Prediction{
        id: "both",
        arrival_time: ~U[2020-02-01T01:00:00Z],
        departure_time: ~U[2020-02-01T01:00:00Z]
      }

      p4 = %Prediction{id: "neither", arrival_time: nil, departure_time: nil}

      actual = Builder.build([p1, p2, p3, p4], [], @now)
      expected = to_departures([p1, p2, p3])

      assert Enum.sort(actual) == Enum.sort(expected)
    end

    test "filters out departures in the past" do
      p1 = %Prediction{id: "1", arrival_time: ~U[2020-01-01T00:00:00Z]}

      p2 = %Prediction{
        id: "2",
        arrival_time: ~U[2020-01-01T00:00:00Z],
        departure_time: ~U[2020-01-01T02:00:00Z]
      }

      p3 = %Prediction{id: "3", departure_time: ~U[2020-01-01T00:00:00Z]}
      p4 = %Prediction{id: "4", departure_time: ~U[2020-01-01T02:00:00Z]}
      p5 = %Prediction{id: "5", arrival_time: ~U[2020-02-01T00:00:00Z]}

      assert Builder.build([p1, p2, p3, p4, p5], [], @now) == to_departures([p2, p4, p5])
    end

    test "filters out extra departures for multi-route trips" do
      p1 = %Prediction{
        id: "1",
        trip: %Trip{id: "47610992", route_id: "214216"},
        route: %Route{id: "214"},
        departure_time: ~U[2020-01-01T01:00:00Z]
      }

      p2 = %Prediction{
        id: "2",
        trip: %Trip{id: "47610992", route_id: "214216"},
        route: %Route{id: "216"},
        departure_time: ~U[2020-01-01T01:00:00Z]
      }

      p3 = %Prediction{
        id: "3",
        trip: %Trip{id: "47610992", route_id: "214216"},
        route: %Route{id: "214216"},
        departure_time: ~U[2020-01-01T01:00:00Z]
      }

      p4 = %Prediction{
        id: "4",
        trip: nil,
        route: %Route{id: "214216"},
        departure_time: ~U[2020-01-01T01:00:00Z]
      }

      p5 = %Prediction{
        id: "5",
        trip: %Trip{id: "47610994", route_id: "214216"},
        route: nil,
        departure_time: ~U[2020-01-01T01:00:00Z]
      }

      actual = Builder.build([p1, p2, p3, p4, p5], [], @now)
      expected = to_departures([p3, p4, p5])

      assert Enum.sort(actual) == Enum.sort(expected)
    end

    test "filters out departures for departed vehicles" do
      p1 = %Prediction{
        id: "1",
        stop: %Stop{id: "2"},
        trip: %Trip{id: "t1", stops: ["1", "2", "3"]},
        vehicle: %Vehicle{trip_id: "t1", stop_id: "3", current_status: :in_transit_to},
        departure_time: ~U[2020-01-01T01:00:00Z]
      }

      p2 = %Prediction{
        id: "2",
        stop: %Stop{id: "2"},
        trip: %Trip{id: "t11", stops: ["1", "2", "3"]},
        vehicle: %Vehicle{trip_id: "t11", stop_id: "2", current_status: :in_transit_to},
        departure_time: ~U[2020-01-01T01:00:00Z]
      }

      p3 = %Prediction{
        id: "3",
        stop: %Stop{id: "2"},
        trip: %Trip{id: "t21", stops: ["3", "2", "1"]},
        vehicle: %Vehicle{trip_id: "t22", stop_id: "1", current_status: :stopped_at},
        departure_time: ~U[2020-01-01T01:00:00Z]
      }

      p4 = %Prediction{
        id: "4",
        stop: %Stop{id: "2"},
        trip: %Trip{id: "t31", stops: []},
        vehicle: %Vehicle{trip_id: "t31", stop_id: "3", current_status: :incoming_at},
        departure_time: ~U[2020-01-01T01:00:00Z]
      }

      p5 = %Prediction{
        id: "5",
        stop: %Stop{id: "2"},
        trip: %Trip{id: "t41", stops: ["1", "2", "3"]},
        vehicle: %Vehicle{trip_id: "t41", stop_id: nil, current_status: :incoming_at},
        departure_time: ~U[2020-01-01T01:00:00Z]
      }

      assert Builder.build([p1, p2, p3, p4, p5], [], @now) == to_departures([p2, p3, p4, p5])
    end

    test "returns only the earliest departure on each trip" do
      p1 = %Prediction{id: "1", trip: %Trip{id: "t1"}, departure_time: ~U[2020-02-01T00:00:00Z]}
      p2 = %Prediction{id: "2", trip: %Trip{id: "t1"}, departure_time: ~U[2020-02-01T00:01:00Z]}
      p3 = %Prediction{id: "3", trip: %Trip{id: "t2"}, departure_time: ~U[2020-02-01T01:01:00Z]}
      p4 = %Prediction{id: "4", trip: %Trip{id: "t2"}, departure_time: ~U[2020-02-01T01:00:00Z]}
      p5 = %Prediction{id: "5", trip: %Trip{id: nil}, departure_time: ~U[2020-02-01T00:00:00Z]}
      p6 = %Prediction{id: "6", trip: nil, departure_time: ~U[2020-02-01T00:00:00Z]}

      actual = Builder.build([p1, p2, p3, p4, p5, p6], [], @now)
      expected = to_departures([p1, p4, p5, p6])

      assert Enum.sort(actual) == Enum.sort(expected)
    end

    test "sorts departures by arrival time if present, departure time if not" do
      # arrives earlier, departs later
      p1 = %Prediction{
        id: "1",
        arrival_time: ~U[2020-02-01T01:00:01Z],
        departure_time: ~U[2020-02-01T01:00:05Z]
      }

      # arrives later, departs earlier
      p2 = %Prediction{
        id: "2",
        arrival_time: ~U[2020-02-01T01:00:02Z],
        departure_time: ~U[2020-02-01T01:00:03Z]
      }

      assert Builder.build([p2, p1], [], @now) == to_departures([p1, p2])
    end

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

      assert expected == Builder.build(predictions, schedules, @now)
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

      assert expected == Builder.build(predictions, schedules, @now)
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

      assert expected == Builder.build(predictions, schedules, @now)
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
        arrival_time: ~U[2020-02-01T00:00:00Z],
        departure_time: ~U[2020-02-02T00:00:00Z],
        trip: %Trip{id: "t4"}
      }

      schedules = [s1, s2]

      expected = [
        %Departure{prediction: nil, schedule: s2},
        %Departure{prediction: p2, schedule: nil},
        %Departure{prediction: p1, schedule: s1},
        %Departure{prediction: p3, schedule: nil}
      ]

      assert expected == Builder.build(predictions, schedules, @now)
    end

    test "filters out departures that have been marked cancelled" do
      p1 = %Prediction{id: "p1", departure_time: ~U[2020-02-01T00:00:00Z], trip: %Trip{id: "t7"}}

      p2 = %Prediction{
        id: "p2",
        departure_time: ~U[2020-02-01T01:00:00Z],
        trip: %Trip{id: "t3"},
        schedule_relationship: :cancelled
      }

      predictions = [p1, p2]

      s1 = %Schedule{id: "s1", departure_time: ~U[2020-02-01T01:01:00Z], trip: %Trip{id: "t3"}}
      s2 = %Schedule{id: "s2", departure_time: ~U[2020-02-01T00:01:00Z], trip: %Trip{id: "t7"}}
      schedules = [s1, s2]

      expected = [%Departure{prediction: p1, schedule: s2}]

      assert expected == Builder.build(predictions, schedules, @now)
    end

    test "filters out departures that have been marked skipped" do
      p1 = %Prediction{id: "p1", departure_time: ~U[2020-02-01T00:00:00Z], trip: %Trip{id: "t7"}}

      p2 = %Prediction{
        id: "p2",
        departure_time: ~U[2020-02-01T01:00:00Z],
        trip: %Trip{id: "t3"},
        schedule_relationship: :skipped
      }

      predictions = [p1, p2]

      s1 = %Schedule{id: "s1", departure_time: ~U[2020-02-01T01:01:00Z], trip: %Trip{id: "t3"}}
      s2 = %Schedule{id: "s2", departure_time: ~U[2020-02-01T00:01:00Z], trip: %Trip{id: "t7"}}
      schedules = [s1, s2]

      expected = [%Departure{prediction: p1, schedule: s2}]

      assert expected == Builder.build(predictions, schedules, @now)
    end
  end
end
