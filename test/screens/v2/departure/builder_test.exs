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
               MapSet.new(Builder.get_relevant_departures(departures, now))
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
               MapSet.new(Builder.get_relevant_departures(departures, now))
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
               MapSet.new(Builder.get_relevant_departures(departures, now))
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
               MapSet.new(Builder.get_relevant_departures(departures, now))
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
               MapSet.new(Builder.get_relevant_departures(departures, now))
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

      assert expected ==
               Builder.merge_predictions_and_schedules(predictions, schedules, schedules)
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

      assert expected ==
               Builder.merge_predictions_and_schedules(predictions, schedules, schedules)
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

      assert expected ==
               Builder.merge_predictions_and_schedules(predictions, schedules, schedules)
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

      assert expected ==
               Builder.merge_predictions_and_schedules(predictions, schedules, schedules)
    end
  end
end
