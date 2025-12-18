defmodule Screens.V2.RDSTest do
  use ExUnit.Case, async: true

  alias Screens.Headways
  alias Screens.Lines.Line
  alias Screens.Predictions.Prediction
  alias Screens.RoutePatterns.RoutePattern
  alias Screens.Routes.Route
  alias Screens.Schedules.Schedule
  alias Screens.Stops.Stop
  alias Screens.Trips.Trip
  alias Screens.V2.Departure
  alias Screens.V2.RDS
  alias ScreensConfig.Departures
  alias ScreensConfig.Departures.{Query, Section}

  import Screens.Inject
  import Mox
  setup :verify_on_exit!

  @departure injected(Departure)
  @headways injected(Headways)
  @route_pattern injected(RoutePattern)
  @stop injected(Stop)

  setup do
    stub(@departure, :fetch, fn _, _ -> {:ok, []} end)
    stub(@headways, :get, fn _, _ -> nil end)
    stub(@route_pattern, :fetch, fn _ -> {:ok, []} end)
    stub(@stop, :fetch, fn %{ids: ids}, true -> {:ok, Enum.map(ids, &stop/1)} end)
    :ok
  end

  describe "get/1" do
    defp no_departures(stop_id, line_id, headsign, headways \\ nil) do
      %RDS{
        stop: %Stop{id: stop_id},
        line: %Line{id: line_id},
        headsign: headsign,
        state: %RDS.NoDepartures{headways: headways}
      }
    end

    defp station(id, child_stop_ids) do
      %Stop{id: id, child_stops: Enum.map(child_stop_ids, &stop/1)}
    end

    defp stop(id), do: %Stop{id: id, location_type: 0}

    test "creates destinations from typical route patterns" do
      stop_ids = ~w[s0 s1]

      expect(@stop, :fetch, fn %{ids: ^stop_ids}, true ->
        {:ok, [station("s0", ~w[sA sB]), station("s1", ~w[sC])]}
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
             stops: [%Stop{id: "otherA"}, %Stop{id: "sB"}, %Stop{id: "otherY"}]
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
               {:ok,
                [
                  no_departures("sA", "l1", "hA"),
                  no_departures("sB", "l2", "hB"),
                  no_departures("sC", "l2", "hC")
                ]}
             ]
    end

    test "creates destinations from upcoming predicted and scheduled departures" do
      now = ~U[2024-10-11 12:00:00Z]

      expect(@departure, :fetch, fn
        %{direction_id: 0, route_type: :bus, stop_ids: ["s0"]}, [now: ^now] ->
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
                  departure_time: ~U[2024-10-11 14:30:00Z],
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
               {:ok, [no_departures("s1", "l1", "h1"), no_departures("s2", "l2", "h2")]}
             ]
    end

    test "filters out the drop off only departures at the current stop id and route patterns" do
      now = ~U[2024-10-11 12:00:00Z]
      stop_ids = ~w[s0 s1 s2]

      expect(@departure, :fetch, fn
        %{direction_id: 0, route_type: :bus, stop_ids: ^stop_ids}, [now: ^now] ->
          {
            :ok,
            [
              %Departure{
                prediction: %Prediction{
                  arrival_time: ~U[2024-10-11 12:27:00Z],
                  departure_time: ~U[2024-10-11 12:30:00Z],
                  route: %Route{id: "r1", line: %Line{id: "l1"}},
                  stop: %Stop{id: "s1"},
                  trip: %Trip{headsign: "other1", pattern_headsign: "h1"}
                },
                schedule: nil
              }
            ]
          }
      end)

      expect(@route_pattern, :fetch, fn %{stop_ids: ^stop_ids} ->
        {:ok,
         [
           %RoutePattern{
             id: "p1",
             headsign: "h2",
             route: %Route{id: "r2", line: %Line{id: "l2"}},
             stops: [%Stop{id: "s1"}, %Stop{id: "s2"}],
             typicality: 1
           }
         ]}
      end)

      departures = %Departures{
        sections: [
          %Section{
            query: %Query{
              params: %Query.Params{
                direction_id: 0,
                route_type: :bus,
                stop_ids: ["s0", "s1", "s2"]
              }
            }
          }
        ]
      }

      assert RDS.get(departures, now) == [
               {:ok, [no_departures("s1", "l1", "h1"), no_departures("s1", "l2", "h2")]}
             ]
    end

    test "NoDepartures includes a headway range for stops that have one" do
      now = ~U[2024-10-11 12:00:00Z]
      expect(@headways, :get, fn "s1", ^now -> {5, 10} end)

      expect(@route_pattern, :fetch, fn %{stop_ids: ~w[s1]} ->
        {:ok,
         [
           %RoutePattern{
             id: "p1",
             headsign: "h1",
             route: %Route{id: "r1", line: %Line{id: "l1"}},
             stops: [%Stop{id: "first_stop"}, %Stop{id: "s1"}, %Stop{id: "last_stop"}]
           }
         ]}
      end)

      departures = %Departures{
        sections: [%Section{query: %Query{params: %Query.Params{stop_ids: ~w[s1]}}}]
      }

      assert RDS.get(departures, now) == [{:ok, [no_departures("s1", "l1", "h1", {5, 10})]}]
    end
  end

  describe "get/1 API failure" do
    test "returns :error when stop fetch fails" do
      stop_ids = ~w[s0 s1]

      expect(@stop, :fetch, fn %{ids: ^stop_ids}, true -> :error end)

      departures = %Departures{
        sections: [
          %Section{query: %Query{params: %Query.Params{stop_ids: stop_ids}}}
        ]
      }

      assert RDS.get(departures) == [:error]
    end

    test "returns :error when route_pattern fetch fails" do
      stop_ids = ~w[s0 s1]

      expect(@route_pattern, :fetch, fn %{stop_ids: ^stop_ids, typicality: 1} ->
        :error
      end)

      departures = %Departures{
        sections: [
          %Section{query: %Query{params: %Query.Params{stop_ids: stop_ids}}}
        ]
      }

      assert RDS.get(departures) == [:error]
    end

    test "returns :error when departure fetch fails" do
      now = ~U[2024-10-11 12:00:00Z]
      stop_ids = ~w[s0]

      expect(@departure, :fetch, fn %{stop_ids: ^stop_ids}, [now: ^now] -> :error end)

      departures = %Departures{
        sections: [
          %Section{query: %Query{params: %Query.Params{stop_ids: stop_ids}}}
        ]
      }

      assert RDS.get(departures, now) == [:error]
    end

    test "returns :error for the failing section when multiple sections exist" do
      now = ~U[2024-10-11 12:00:00Z]
      stop_ids_primary = ~w[s0]
      stop_ids_secondary = ~w[s1]

      stub(@departure, :fetch, fn %{stop_ids: stop_ids}, [now: ^now] ->
        case stop_ids do
          ^stop_ids_primary -> {:ok, []}
          ^stop_ids_secondary -> :error
        end
      end)

      departures = %Departures{
        sections: [
          %Section{query: %Query{params: %Query.Params{stop_ids: stop_ids_primary}}},
          %Section{query: %Query{params: %Query.Params{stop_ids: stop_ids_secondary}}}
        ]
      }

      assert RDS.get(departures, now) == [{:ok, []}, :error]
    end
  end
end
