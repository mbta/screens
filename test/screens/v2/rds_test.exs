defmodule Screens.V2.RDSTest do
  use ExUnit.Case, async: true

  alias Screens.Alerts.Alert
  alias Screens.Config.Cache
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
  import Screens.TestSupport.InformedEntityBuilder
  import Mox
  setup :verify_on_exit!

  @alert injected(Alert)
  @departure injected(Departure)
  @headways injected(Headways)
  @route_pattern injected(RoutePattern)
  @schedule injected(Schedule)
  @stop injected(Stop)
  @config_cache injected(Cache)

  setup do
    stub(@alert, :fetch, fn _ -> {:ok, []} end)
    stub(@departure, :fetch, fn _, _ -> {:ok, []} end)
    stub(@headways, :get, fn _, _ -> nil end)
    stub(@route_pattern, :fetch, fn _ -> {:ok, []} end)
    stub(@schedule, :fetch, fn _, _ -> {:ok, []} end)
    stub(@stop, :fetch, fn %{ids: ids}, true -> {:ok, Enum.map(ids, &stop/1)} end)
    stub(@config_cache, :disabled_modes, fn -> [] end)
    :ok
  end

  describe "get/1" do
    defp no_service(stop_id, line_id, headsign) do
      %RDS{
        stop: %Stop{id: stop_id},
        line: %Line{id: line_id},
        headsign: headsign,
        state: %RDS.NoService{
          routes: [
            %Screens.Routes.Route{
              id: "r1",
              short_name: nil,
              long_name: nil,
              direction_names: nil,
              direction_destinations: nil,
              type: :bus,
              line: %Screens.Lines.Line{
                id: "l1",
                long_name: nil,
                short_name: nil,
                sort_order: nil
              }
            },
            %Screens.Routes.Route{
              id: "r2",
              short_name: nil,
              long_name: nil,
              direction_names: nil,
              direction_destinations: nil,
              type: :bus,
              line: %Screens.Lines.Line{
                id: "l2",
                long_name: nil,
                short_name: nil,
                sort_order: nil
              }
            }
          ]
        }
      }
    end

    defp countdowns(stop_id, line_id, headsign, departures) do
      %RDS{
        stop: %Stop{id: stop_id},
        line: %Line{id: line_id},
        headsign: headsign,
        state: %RDS.Countdowns{departures: departures}
      }
    end

    defp first_trip(stop_id, line_id, headsign, schedule) do
      %RDS{
        stop: %Stop{id: stop_id},
        line: %Line{id: line_id},
        headsign: headsign,
        state: %RDS.FirstTrip{
          first_scheduled_departure: %Departure{prediction: nil, schedule: schedule}
        }
      }
    end

    defp service_ended(stop_id, line_id, headsign, schedule) do
      %RDS{
        stop: %Stop{id: stop_id},
        line: %Line{id: line_id},
        headsign: headsign,
        state: %RDS.ServiceEnded{
          last_scheduled_departure: %Departure{prediction: nil, schedule: schedule}
        }
      }
    end

    defp headways(stop_id, line_id, headsign, first_scheduled_departure, route_id, direction_name) do
      %RDS{
        stop: %Stop{id: stop_id},
        line: %Line{id: line_id},
        headsign: headsign,
        state: %RDS.Headways{
          departure: %Departure{prediction: nil, schedule: first_scheduled_departure},
          route_id: route_id,
          direction_name: direction_name,
          range: {5, 10}
        }
      }
    end

    defp station(id, child_stop_ids) do
      %Stop{id: id, child_stops: Enum.map(child_stop_ids, &stop/1)}
    end

    defp stop(id), do: %Stop{id: id, location_type: 0}

    # Standard test fixture: 3 route patterns across 2 routes and 2 lines
    defp standard_route_patterns do
      [
        %RoutePattern{
          id: "A",
          headsign: "hA",
          route: %Route{id: "r1", line: %Line{id: "l1"}, type: :bus},
          stops: [%Stop{id: "sA"}, %Stop{id: "otherX"}]
        },
        %RoutePattern{
          id: "B",
          headsign: "hB",
          route: %Route{id: "r2", line: %Line{id: "l2"}, type: :bus},
          stops: [%Stop{id: "otherA"}, %Stop{id: "sB"}, %Stop{id: "otherY"}]
        },
        %RoutePattern{
          id: "C",
          headsign: "hC",
          route: %Route{id: "r2", line: %Line{id: "l2"}, type: :bus},
          stops: [%Stop{id: "sC"}, %Stop{id: "otherZ"}]
        }
      ]
    end

    defp expect_standard_stations(stop_ids) do
      expect(@stop, :fetch, fn %{ids: ^stop_ids}, true ->
        {:ok, [station("s0", ~w[sA sB]), station("s1", ~w[sC])]}
      end)
    end

    defp expect_standard_route_patterns(stop_ids, patterns \\ nil) do
      patterns = patterns || standard_route_patterns()

      expect(@route_pattern, :fetch, fn %{route_type: :bus, stop_ids: ^stop_ids, typicality: 1} ->
        {:ok, patterns}
      end)
    end

    test "creates no service destinations from typical route patterns with no departures" do
      stop_ids = ~w[s0 s1]

      expect_standard_stations(stop_ids)
      expect_standard_route_patterns(stop_ids)

      departures = %Departures{
        sections: [
          %Section{query: %Query{params: %Query.Params{route_type: :bus, stop_ids: stop_ids}}}
        ]
      }

      assert RDS.get(departures) == [
               {:ok,
                [
                  no_service("sA", "l1", "hA"),
                  no_service("sB", "l2", "hB"),
                  no_service("sC", "l2", "hC")
                ]}
             ]
    end

    test "creates destinations from upcoming predicted and scheduled departures" do
      now = ~U[2024-10-11 12:00:00Z]

      expect(@headways, :get, fn _, _ -> nil end)
      expect(@headways, :get, fn _, _ -> nil end)

      expected_departures_one = [
        %Departure{
          prediction: %Prediction{
            departure_time: ~U[2024-10-11 12:30:00Z],
            route: %Route{id: "r1", line: %Line{id: "l1"}},
            stop: %Stop{id: "s1"},
            trip: %Trip{headsign: "other1", pattern_headsign: "h1"}
          },
          schedule: nil
        }
      ]

      expected_departures_two = [
        %Departure{
          prediction: nil,
          schedule: %Schedule{
            departure_time: ~U[2024-10-11 13:15:00Z],
            route: %Route{id: "r2", line: %Line{id: "l2"}},
            stop: %Stop{id: "s2"},
            trip: %Trip{headsign: "other2", pattern_headsign: "h2"}
          }
        }
      ]

      expect(@departure, :fetch, fn
        %{direction_id: 0, route_type: :bus, stop_ids: ["s0"]}, [now: ^now] ->
          {
            :ok,
            expected_departures_one ++
              expected_departures_two ++
              [
                %Departure{
                  prediction: %Prediction{
                    # further in the future than the cutoff
                    departure_time: ~U[2024-10-11 14:30:00Z],
                    route: %Route{id: "r3", line: %Line{id: "l3"}, type: :bus},
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
               {:ok,
                [
                  countdowns("s1", "l1", "h1", expected_departures_one),
                  countdowns("s2", "l2", "h2", expected_departures_two)
                ]}
             ]
    end

    test "filters out the drop off only departures at the current stop id and route patterns" do
      now = ~U[2024-10-11 12:00:00Z]
      stop_ids = ~w[s0 s1 s2]

      expected_departures = [
        %Departure{
          prediction: %Prediction{
            arrival_time: ~U[2024-10-11 12:27:00Z],
            departure_time: ~U[2024-10-11 12:30:00Z],
            route: %Route{id: "r1", line: %Line{id: "l1"}, type: :bus},
            stop: %Stop{id: "s1"},
            trip: %Trip{headsign: "other1", pattern_headsign: "h1"}
          },
          schedule: nil
        }
      ]

      expect(@departure, :fetch, fn
        %{direction_id: 0, route_type: :bus, stop_ids: ^stop_ids}, [now: ^now] ->
          {
            :ok,
            expected_departures
          }
      end)

      expect(@route_pattern, :fetch, fn %{stop_ids: ^stop_ids} ->
        {:ok,
         [
           %RoutePattern{
             id: "p1",
             headsign: "h2",
             route: %Route{id: "r2", line: %Line{id: "l2"}, type: :bus},
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
               {:ok,
                [
                  countdowns("s1", "l1", "h1", expected_departures),
                  no_service("s1", "l2", "h2")
                ]}
             ]
    end

    test "creates first trip state when in the early morning with no headways" do
      now = ~U[2024-10-11 10:44:00Z]
      stop_ids = ~w[s0 s1]

      first_schedule =
        %Schedule{
          departure_time: ~U[2024-10-11 10:45:00Z],
          route: %Route{id: "r1", line: %Line{id: "l1"}, type: :bus},
          stop: %Stop{id: "sA"},
          trip: %Trip{headsign: "h1", pattern_headsign: "hA"}
        }

      second_schedule = %Schedule{
        departure_time: ~U[2024-10-11 10:45:00Z],
        route: %Route{id: "r2", line: %Line{id: "l2"}, type: :bus},
        stop: %Stop{id: "sB"},
        trip: %Trip{headsign: "h2", pattern_headsign: "hB"}
      }

      third_schedule =
        %Schedule{
          departure_time: ~U[2024-10-11 10:45:00Z],
          route: %Route{id: "r2", line: %Line{id: "l2"}, type: :bus},
          stop: %Stop{id: "sC"},
          trip: %Trip{headsign: "h3", pattern_headsign: "hC"}
        }

      all_schedules = [first_schedule, second_schedule, third_schedule]

      departures = %Departures{
        sections: [
          %Section{query: %Query{params: %Query.Params{route_type: :bus, stop_ids: stop_ids}}}
        ]
      }

      expect(@schedule, :fetch, fn %{stop_ids: ^stop_ids}, _now -> {:ok, all_schedules} end)
      expect_standard_stations(stop_ids)
      expect_standard_route_patterns(stop_ids)

      assert RDS.get(departures, now) == [
               {:ok,
                [
                  first_trip("sA", "l1", "hA", first_schedule),
                  first_trip("sB", "l2", "hB", second_schedule),
                  first_trip("sC", "l2", "hC", third_schedule)
                ]}
             ]
    end

    test "creates first trip state when in the early morning adjusted for headways" do
      now = ~U[2024-10-11 10:34:00Z]
      stop_ids = ~w[s0 s1]

      first_schedule =
        %Schedule{
          departure_time: ~U[2024-10-11 10:45:00Z],
          route: %Route{id: "r1", line: %Line{id: "l1"}, type: :bus},
          stop: %Stop{id: "sA"},
          trip: %Trip{headsign: "h1", pattern_headsign: "hA"}
        }

      second_schedule = %Schedule{
        departure_time: ~U[2024-10-11 10:45:00Z],
        route: %Route{id: "r2", line: %Line{id: "l2"}, type: :bus},
        stop: %Stop{id: "sB"},
        trip: %Trip{headsign: "h2", pattern_headsign: "hB"}
      }

      third_schedule =
        %Schedule{
          departure_time: ~U[2024-10-11 10:45:00Z],
          route: %Route{id: "r2", line: %Line{id: "l2"}, type: :bus},
          stop: %Stop{id: "sC"},
          trip: %Trip{headsign: "h3", pattern_headsign: "hC"}
        }

      all_schedules = [first_schedule, second_schedule, third_schedule]

      departures = %Departures{
        sections: [
          %Section{query: %Query{params: %Query.Params{route_type: :bus, stop_ids: stop_ids}}}
        ]
      }

      stub(@headways, :get, fn _, _ -> {5, 10} end)

      expect(@schedule, :fetch, fn %{stop_ids: ^stop_ids}, _now -> {:ok, all_schedules} end)
      expect_standard_stations(stop_ids)
      expect_standard_route_patterns(stop_ids)

      assert RDS.get(departures, now) == [
               {:ok,
                [
                  first_trip("sA", "l1", "hA", first_schedule),
                  first_trip("sB", "l2", "hB", second_schedule),
                  first_trip("sC", "l2", "hC", third_schedule)
                ]}
             ]
    end

    test "creates service ended state when after last scheduled departure" do
      now = ~U[2024-10-11 10:50:00Z]
      stop_ids = ~w[s0 s1]

      first_schedule =
        %Schedule{
          departure_time: ~U[2024-10-11 10:45:00Z],
          route: %Route{id: "r1", line: %Line{id: "l1"}, type: :bus},
          stop: %Stop{id: "sA"},
          trip: %Trip{headsign: "h1", pattern_headsign: "hA"}
        }

      second_schedule = %Schedule{
        departure_time: ~U[2024-10-11 10:45:00Z],
        route: %Route{id: "r2", line: %Line{id: "l2"}, type: :bus},
        stop: %Stop{id: "sB"},
        trip: %Trip{headsign: "h2", pattern_headsign: "hB"}
      }

      third_schedule =
        %Schedule{
          departure_time: ~U[2024-10-11 10:45:00Z],
          route: %Route{id: "r2", line: %Line{id: "l2"}, type: :bus},
          stop: %Stop{id: "sC"},
          trip: %Trip{headsign: "h3", pattern_headsign: "hC"}
        }

      all_schedules = [first_schedule, second_schedule, third_schedule]

      departures = %Departures{
        sections: [
          %Section{query: %Query{params: %Query.Params{route_type: :bus, stop_ids: stop_ids}}}
        ]
      }

      stub(@headways, :get, fn _, _ -> {5, 10} end)

      expect(@schedule, :fetch, fn %{stop_ids: ^stop_ids}, _now -> {:ok, all_schedules} end)
      expect_standard_stations(stop_ids)
      expect_standard_route_patterns(stop_ids)

      assert RDS.get(departures, now) == [
               {:ok,
                [
                  service_ended("sA", "l1", "hA", first_schedule),
                  service_ended("sB", "l2", "hB", second_schedule),
                  service_ended("sC", "l2", "hC", third_schedule)
                ]}
             ]
    end

    test "does not create NoService destinations for those affected by an alert that affects the home stop" do
      stop_ids = ~w[s0 s1]
      now = ~U[2024-10-11 10:44:00Z]

      expect(@alert, :fetch, fn [activities: [:board], stop_id: ["s0", "s1"], include_all?: true] ->
        {:ok,
         [
           %Alert{
             id: "1",
             effect: :stop_closure,
             informed_entities: [ie(stop_id: "s0", route: "r1"), ie(stop_id: "sA", route: "r1")],
             active_period: [{now, nil}]
           }
         ]}
      end)

      expect_standard_stations(stop_ids)
      expect_standard_route_patterns(stop_ids)

      departures = %Departures{
        sections: [
          %Section{query: %Query{params: %Query.Params{route_type: :bus, stop_ids: stop_ids}}}
        ]
      }

      assert RDS.get(departures) == [
               {:ok,
                [
                  countdowns("sA", "l1", "hA", []),
                  no_service("sB", "l2", "hB"),
                  no_service("sC", "l2", "hC")
                ]}
             ]
    end

    test "does not create NoService for destinations affected by alert on entire route" do
      stop_ids = ~w[s0 s1]
      now = ~U[2024-10-11 10:44:00Z]

      # Alert affects entire route r1 (no direction_id, no stop)
      expect(@alert, :fetch, fn [activities: [:board], stop_id: ["s0", "s1"], include_all?: true] ->
        {:ok,
         [
           %Alert{
             id: "1",
             effect: :suspension,
             informed_entities: [ie(route: "r1")],
             active_period: [{now, nil}]
           }
         ]}
      end)

      expect_standard_stations(stop_ids)
      expect_standard_route_patterns(stop_ids)

      departures = %Departures{
        sections: [
          %Section{query: %Query{params: %Query.Params{route_type: :bus, stop_ids: stop_ids}}}
        ]
      }

      assert RDS.get(departures) == [
               {:ok,
                [
                  countdowns("sA", "l1", "hA", []),
                  no_service("sB", "l2", "hB"),
                  no_service("sC", "l2", "hC")
                ]}
             ]
    end

    test "does not create NoService for destinations affected by alert on route in one direction" do
      stop_ids = ~w[s0 s1]
      now = ~U[2024-10-11 10:44:00Z]

      # Alert affects route r2 in direction 0 only
      expect(@alert, :fetch, fn [activities: [:board], stop_id: ["s0", "s1"], include_all?: true] ->
        {:ok,
         [
           %Alert{
             id: "1",
             effect: :shuttle,
             informed_entities: [ie(route: "r2", direction_id: 0)],
             active_period: [{now, nil}]
           }
         ]}
      end)

      expect_standard_stations(stop_ids)

      expect(@route_pattern, :fetch, fn %{route_type: :bus, stop_ids: ^stop_ids, typicality: 1} ->
        {:ok,
         [
           %RoutePattern{
             id: "A",
             headsign: "hA",
             route: %Route{id: "r1", line: %Line{id: "l1"}, type: :bus},
             stops: [%Stop{id: "sA"}, %Stop{id: "otherX"}],
             direction_id: 1
           },
           %RoutePattern{
             id: "B",
             headsign: "hB",
             route: %Route{id: "r2", line: %Line{id: "l2"}, type: :bus},
             stops: [%Stop{id: "otherA"}, %Stop{id: "sB"}, %Stop{id: "otherY"}],
             direction_id: 0
           },
           %RoutePattern{
             id: "C",
             headsign: "hC",
             route: %Route{id: "r2", line: %Line{id: "l2"}, type: :bus},
             stops: [%Stop{id: "sC"}, %Stop{id: "otherZ"}],
             direction_id: 1
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
                  no_service("sA", "l1", "hA"),
                  countdowns("sB", "l2", "hB", []),
                  no_service("sC", "l2", "hC")
                ]}
             ]
    end

    test "does not create NoService for destinations affected by alert on route type" do
      stop_ids = ~w[s0 s1]
      now = ~U[2024-10-11 10:44:00Z]

      # Alert affects all bus routes (route_type 3)
      expect(@alert, :fetch, fn [activities: [:board], stop_id: ["s0", "s1"], include_all?: true] ->
        {:ok,
         [
           %Alert{
             id: "1",
             effect: :detour,
             informed_entities: [ie(route_type: 3)],
             active_period: [{now, nil}]
           }
         ]}
      end)

      expect_standard_stations(stop_ids)
      expect_standard_route_patterns(stop_ids)

      departures = %Departures{
        sections: [
          %Section{query: %Query{params: %Query.Params{route_type: :bus, stop_ids: stop_ids}}}
        ]
      }

      # All destinations are affected since the alert targets the entire bus route type
      assert RDS.get(departures) == [
               {:ok,
                [
                  countdowns("sA", "l1", "hA", []),
                  countdowns("sB", "l2", "hB", []),
                  countdowns("sC", "l2", "hC", [])
                ]}
             ]
    end

    test "creates NoService for destinations not affected by alerts" do
      stop_ids = ~w[s0 s1]
      now = ~U[2024-10-11 10:44:00Z]

      # Alert that affects another route type, another route, and another stop
      # None of the destinations should be affected
      expect(@alert, :fetch, fn [activities: [:board], stop_id: ["s0", "s1"], include_all?: true] ->
        {:ok,
         [
           %Alert{
             id: "1",
             effect: :detour,
             informed_entities: [ie(route: 4), ie(route: "otherRoute"), ie(stop_id: "otherStop")],
             active_period: [{now, nil}]
           }
         ]}
      end)

      expect_standard_stations(stop_ids)
      expect_standard_route_patterns(stop_ids)

      departures = %Departures{
        sections: [
          %Section{query: %Query{params: %Query.Params{route_type: :bus, stop_ids: stop_ids}}}
        ]
      }

      assert RDS.get(departures) == [
               {:ok,
                [
                  no_service("sA", "l1", "hA"),
                  no_service("sB", "l2", "hB"),
                  no_service("sC", "l2", "hC")
                ]}
             ]
    end

    test "creates headways for destinations" do
      now = ~U[2024-10-11 11:44:00Z]
      stop_ids = ~w[s0 s1]

      first_schedule_one =
        %Schedule{
          departure_time: ~U[2024-10-11 10:45:00Z],
          route: %Route{
            id: "r1",
            line: %Line{id: "l1"},
            type: :bus,
            direction_names: ["Northbound", "Southbound"]
          },
          stop: %Stop{id: "sA"},
          trip: %Trip{headsign: "h1", pattern_headsign: "hA", direction_id: 0}
        }

      last_schedule_one =
        %Schedule{
          departure_time: ~U[2024-10-12 01:45:00Z],
          route: %Route{
            id: "r1",
            line: %Line{id: "l1"},
            type: :bus,
            direction_names: ["Northbound", "Southbound"]
          },
          stop: %Stop{id: "sA"},
          trip: %Trip{headsign: "h1", pattern_headsign: "hA", direction_id: 0}
        }

      first_schedule_two = %Schedule{
        departure_time: ~U[2024-10-11 10:45:00Z],
        route: %Route{
          id: "r2",
          line: %Line{id: "l2"},
          type: :bus,
          direction_names: ["Eastbound", "Westbound"]
        },
        stop: %Stop{id: "sB"},
        trip: %Trip{headsign: "h2", pattern_headsign: "hB", direction_id: 1}
      }

      last_schedule_two =
        %Schedule{
          departure_time: ~U[2024-10-12 01:45:00Z],
          route: %Route{
            id: "r2",
            line: %Line{id: "l2"},
            type: :bus,
            direction_names: ["Eastbound", "Westbound"]
          },
          stop: %Stop{id: "sB"},
          trip: %Trip{headsign: "h2", pattern_headsign: "hB", direction_id: 1}
        }

      first_schedule_three =
        %Schedule{
          departure_time: ~U[2024-10-11 10:45:00Z],
          route: %Route{
            id: "r2",
            line: %Line{id: "l2"},
            type: :bus,
            direction_names: ["Eastbound", "Westbound"]
          },
          stop: %Stop{id: "sC"},
          trip: %Trip{headsign: "h3", pattern_headsign: "hC", direction_id: 0}
        }

      last_schedule_three =
        %Schedule{
          departure_time: ~U[2024-10-12 01:45:00Z],
          route: %Route{
            id: "r2",
            line: %Line{id: "l2"},
            type: :bus,
            direction_names: ["Eastbound", "Westbound"]
          },
          stop: %Stop{id: "sC"},
          trip: %Trip{headsign: "h3", pattern_headsign: "hC", direction_id: 0}
        }

      all_schedules = [
        first_schedule_one,
        last_schedule_one,
        first_schedule_two,
        last_schedule_two,
        first_schedule_three,
        last_schedule_three
      ]

      departures = %Departures{
        sections: [
          %Section{query: %Query{params: %Query.Params{route_type: :bus, stop_ids: stop_ids}}}
        ]
      }

      stub(@headways, :get, fn _, _ -> {5, 10} end)
      expect(@schedule, :fetch, fn %{stop_ids: ^stop_ids}, _now -> {:ok, all_schedules} end)
      expect_standard_stations(stop_ids)
      expect_standard_route_patterns(stop_ids)

      assert RDS.get(departures, now) == [
               {:ok,
                [
                  headways("sA", "l1", "hA", first_schedule_one, "r1", "Northbound"),
                  headways("sB", "l2", "hB", first_schedule_two, "r2", "Westbound"),
                  headways("sC", "l2", "hC", first_schedule_three, "r2", "Eastbound")
                ]}
             ]
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

      expected_departures = [
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

      stub(@departure, :fetch, fn %{stop_ids: stop_ids}, [now: ^now] ->
        case stop_ids do
          ^stop_ids_primary -> {:ok, expected_departures}
          ^stop_ids_secondary -> :error
        end
      end)

      departures = %Departures{
        sections: [
          %Section{query: %Query{params: %Query.Params{stop_ids: stop_ids_primary}}},
          %Section{query: %Query{params: %Query.Params{stop_ids: stop_ids_secondary}}}
        ]
      }

      assert RDS.get(departures, now) ==
               [{:ok, [countdowns("s1", "l1", "h1", expected_departures)]}, :error]
    end

    test "returns :error when a section has a disabled mode" do
      now = ~U[2024-10-11 12:00:00Z]
      stop_ids = ~w[s0 s1 s2]

      bus_departures = [
        %Departure{
          prediction: %Prediction{
            arrival_time: ~U[2024-10-11 12:27:00Z],
            departure_time: ~U[2024-10-11 12:30:00Z],
            route: %Route{id: "r1", line: %Line{id: "l1"}, type: :bus},
            stop: %Stop{id: "s1"},
            trip: %Trip{headsign: "other1", pattern_headsign: "h1"}
          },
          schedule: nil
        }
      ]

      subway_departures = [
        %Departure{
          prediction: %Prediction{
            arrival_time: ~U[2024-10-11 12:27:00Z],
            departure_time: ~U[2024-10-11 12:30:00Z],
            route: %Route{id: "r2", line: %Line{id: "l2"}, type: :subway},
            stop: %Stop{id: "s1"},
            trip: %Trip{headsign: "other2", pattern_headsign: "h2"}
          },
          schedule: nil
        }
      ]

      stub(@departure, :fetch, fn
        %{direction_id: 0, route_type: :bus, stop_ids: ^stop_ids}, [now: ^now] ->
          {:ok, bus_departures}

        %{direction_id: 0, route_type: :subway, stop_ids: ^stop_ids}, [now: ^now] ->
          {:ok, subway_departures}
      end)

      stub(@config_cache, :disabled_modes, fn -> [:bus] end)

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
          },
          %Section{
            query: %Query{
              params: %Query.Params{
                direction_id: 0,
                route_type: :subway,
                stop_ids: ["s0", "s1", "s2"]
              }
            }
          }
        ]
      }

      assert RDS.get(departures, now) == [
               {:ok, []},
               {:ok, [countdowns("s1", "l2", "h2", subway_departures)]}
             ]
    end
  end
end
