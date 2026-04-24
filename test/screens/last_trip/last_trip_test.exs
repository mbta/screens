defmodule Screens.LastTrip.LastTripTest do
  use ExUnit.Case, async: true

  alias Screens.LastTrip.LastTrip
  alias Screens.Lines.Line
  alias Screens.Predictions.Prediction
  alias Screens.Routes.Route
  alias Screens.Schedules.Schedule
  alias Screens.Stops.Stop
  alias Screens.Trips.Trip

  alias Screens.V2.Departure

  setup do
    departures = [
      %Departure{
        prediction: %Prediction{
          departure_time: ~U[2024-10-11 12:30:00Z],
          route: %Route{id: "r1", line: %Line{id: "l1"}, type: :subway},
          stop: %Stop{id: "s1"},
          trip: %Trip{headsign: "other1", pattern_headsign: "h1"},
          last_trip: true
        },
        schedule: nil
      },
      %Departure{
        prediction: %Prediction{
          departure_time: ~U[2024-10-11 12:20:00Z],
          route: %Route{id: "r1", line: %Line{id: "l1"}, type: :subway},
          stop: %Stop{id: "s1"},
          trip: %Trip{headsign: "other1", pattern_headsign: "h1"},
          last_trip: true
        },
        schedule: nil
      },
      %Departure{
        prediction: %Prediction{
          departure_time: ~U[2024-10-11 12:40:00Z],
          route: %Route{id: "r1", line: %Line{id: "l1"}, type: :subway},
          stop: %Stop{id: "s1"},
          trip: %Trip{headsign: "other1", pattern_headsign: "h1"},
          last_trip: false
        },
        schedule: nil
      },
      %Departure{
        prediction: %Prediction{
          departure_time: ~U[2024-10-11 12:20:00Z],
          route: %Route{id: "r2", line: %Line{id: "l2"}, type: :subway},
          stop: %Stop{id: "s2"},
          trip: %Trip{headsign: "other2", pattern_headsign: "h2"},
          last_trip: true
        },
        schedule: nil
      },
      %Departure{
        prediction: %Prediction{
          departure_time: ~U[2024-10-11 12:40:00Z],
          route: %Route{id: "r2", line: %Line{id: "l2"}, type: :subway},
          stop: %Stop{id: "s2"},
          trip: %Trip{headsign: "other2", pattern_headsign: "h2"},
          last_trip: false
        },
        schedule: nil
      },
      %Departure{
        prediction: nil,
        schedule: %Schedule{
          departure_time: ~U[2024-10-11 13:15:00Z],
          route: %Route{id: "r3", line: %Line{id: "l3"}},
          stop: %Stop{id: "s3"},
          trip: %Trip{headsign: "other3", pattern_headsign: "h3"}
        }
      }
    ]

    {:ok, departures: departures}
  end

  test "last_trip_departure_times/1", %{departures: departures} do
    LastTrip.update_last_trip_cache(departures, DateTime.utc_now())

    assert LastTrip.last_trip_departure_times({"s1", "l1", "h1"}) == [
             ~U[2024-10-11 12:20:00Z],
             ~U[2024-10-11 12:30:00Z]
           ]

    assert LastTrip.last_trip_departure_times({"s2", "l2", "h2"}) == [~U[2024-10-11 12:20:00Z]]
    assert LastTrip.last_trip_departure_times({"s3", "l3", "h3"}) == []
  end
end
