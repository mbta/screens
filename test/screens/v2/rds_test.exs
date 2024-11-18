defmodule Screens.V2.RDSTest do
  use ExUnit.Case, async: true

  alias Screens.Lines.Line
  alias Screens.Predictions.Prediction
  alias Screens.RoutePatterns.RoutePattern
  alias Screens.Routes.Route
  alias Screens.Schedules.Schedule
  alias Screens.Stops.Stop
  alias Screens.Trips.Trip
  alias Screens.V2.Departure
  alias Screens.V2.RDS
  alias ScreensConfig.V2.Departures
  alias ScreensConfig.V2.Departures.{Query, Section}

  import Screens.Inject
  import Mox
  setup :verify_on_exit!

  @departure injected(Departure)
  @route_pattern injected(RoutePattern)
  @stop injected(Stop)

  describe "get/1" do
    setup do
      stub(@departure, :fetch, fn _, _ -> {:ok, []} end)
      stub(@route_pattern, :fetch, fn _ -> {:ok, []} end)
      stub(@stop, :fetch_child_stops, fn ids -> {:ok, Enum.map(ids, &[%Stop{id: &1}])} end)
      :ok
    end

    defp no_departures(stop_id, line_id, headsign) do
      %RDS{
        stop: %Stop{id: stop_id},
        line: %Line{id: line_id},
        headsign: headsign,
        state: %RDS.NoDepartures{}
      }
    end

    test "creates destinations from typical route patterns" do
      stop_ids = ~w[s0 s1]

      expect(@stop, :fetch_child_stops, fn ^stop_ids ->
        {:ok, [[%Stop{id: "sA"}, %Stop{id: "sB"}], [%Stop{id: "sC"}]]}
      end)

      expect(@route_pattern, :fetch, fn %{route_type: :bus, stop_ids: ^stop_ids, typicality: 1} ->
        {:ok,
         [
           %RoutePattern{
             id: "A",
             headsign: "hA",
             route: %Route{id: "r1", line: %Line{id: "l1"}},
             stops: [%Stop{id: "sA"}, %Stop{id: "otherX"}]
           },
           %RoutePattern{
             id: "B",
             headsign: "hB",
             route: %Route{id: "r2", line: %Line{id: "l2"}},
             stops: [%Stop{id: "otherY"}, %Stop{id: "sB"}]
           },
           %RoutePattern{
             id: "C",
             headsign: "hC",
             route: %Route{id: "r2", line: %Line{id: "l2"}},
             stops: [%Stop{id: "sC"}, %Stop{id: "otherZ"}]
           }
         ]}
      end)

      departures = %Departures{
        sections: [
          %Section{query: %Query{params: %Query.Params{route_type: :bus, stop_ids: stop_ids}}}
        ]
      }

      assert RDS.get(departures) == [
               [
                 no_departures("sA", "l1", "hA"),
                 no_departures("sB", "l2", "hB"),
                 no_departures("sC", "l2", "hC")
               ]
             ]
    end

    test "creates destinations from upcoming predicted and scheduled departures" do
      now = ~U[2024-10-11 12:00:00Z]

      expect(@departure, :fetch, fn
        %{direction_id: 0, route_type: :bus, stop_ids: ["s0"]},
        [include_schedules: true, now: ^now] ->
          {
            :ok,
            [
              %Departure{
                prediction: %Prediction{
                  departure_time: ~U[2024-10-11 12:30:00Z],
                  route: %Route{id: "r1", line: %Line{id: "l1"}},
                  stop: %Stop{id: "s1"},
                  trip: %Trip{headsign: "other1", pattern_headsign: "h1"}
                },
                schedule: nil
              },
              %Departure{
                prediction: nil,
                schedule: %Schedule{
                  departure_time: ~U[2024-10-11 13:15:00Z],
                  route: %Route{id: "r2", line: %Line{id: "l2"}},
                  stop: %Stop{id: "s2"},
                  trip: %Trip{headsign: "other2", pattern_headsign: "h2"}
                }
              },
              %Departure{
                prediction: %Prediction{
                  # further in the future than the cutoff
                  departure_time: ~U[2024-10-11 14:00:00Z],
                  route: %Route{id: "r3", line: %Line{id: "l3"}},
                  stop: %Stop{id: "s3"},
                  trip: %Trip{headsign: "other3", pattern_headsign: "h3"}
                },
                schedule: nil
              }
            ]
          }
      end)

      departures = %Departures{
        sections: [
          %Section{
            query: %Query{
              params: %Query.Params{
                direction_id: 0,
                route_type: :bus,
                stop_ids: ["s0"]
              }
            }
          }
        ]
      }

      assert RDS.get(departures, now) == [
               [no_departures("s1", "l1", "h1"), no_departures("s2", "l2", "h2")]
             ]
    end
  end
end
