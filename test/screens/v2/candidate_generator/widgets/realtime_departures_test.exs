defmodule Screens.V2.CandidateGenerator.Widgets.RealtimeDeparturesTest do
  use ExUnit.Case, async: true

  alias Screens.Config.Cache
  alias Screens.Lines.Line
  alias Screens.Predictions.Prediction
  alias Screens.Routes.Route
  alias Screens.Schedules.Schedule
  alias Screens.Stops.Stop
  alias Screens.Trips.Trip
  alias Screens.V2.CandidateGenerator.Widgets.RealtimeDepartures
  alias Screens.V2.Departure
  alias Screens.V2.RDS
  alias Screens.V2.WidgetInstance.Departures, as: DeparturesWidget
  alias Screens.V2.WidgetInstance.Departures.NormalSection
  alias Screens.V2.WidgetInstance.DeparturesNoData
  alias ScreensConfig.Departures, as: DeparturesConfig
  alias ScreensConfig.Departures.{Filters, Header, Layout, Query, Section}
  alias ScreensConfig.Departures.Filters.RouteDirections
  alias ScreensConfig.Departures.Filters.RouteDirections.RouteDirection
  alias ScreensConfig.Screen
  alias ScreensConfig.Screen.BusShelter

  import Screens.Inject
  import Mox
  setup :verify_on_exit!
  @rds injected(RDS)
  @cache injected(Cache)

  @now ~U[2020-04-06T10:00:00Z]

  defp build_schedule(route_id, line_id, type \\ :bus, direction_id \\ 0) do
    %Schedule{
      arrival_time: ~U[2026-01-01 12:37:00Z],
      departure_time: ~U[2026-01-01 12:38:00Z],
      route: %Route{id: route_id, line: %Line{id: line_id}, type: type},
      trip: %Trip{direction_id: direction_id}
    }
  end

  defp build_departure(
         route_id,
         direction_id,
         route_type \\ :bus,
         arrival_time \\ ~U[2026-01-01 12:37:00Z]
       ) do
    %Departure{
      prediction: %Prediction{
        route: %Route{id: route_id, type: route_type},
        trip: %Trip{direction_id: direction_id},
        arrival_time: arrival_time
      }
    }
  end

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
      state: %RDS.FirstTrip{first_schedule: schedule}
    }
  end

  defp service_ended(stop_id, line_id, headsign, schedule) do
    %RDS{
      stop: %Stop{id: stop_id},
      line: %Line{id: line_id},
      headsign: headsign,
      state: %RDS.ServiceEnded{last_schedule: schedule}
    }
  end

  defp headways(
         stop_id,
         line_id,
         headsign,
         route_id,
         direction_name,
         direction_id
       ) do
    %RDS{
      stop: %Stop{id: stop_id},
      line: %Line{id: line_id},
      headsign: headsign,
      state: %RDS.Headways{
        route_id: route_id,
        direction_name: direction_name,
        direction_id: direction_id,
        range: {5, 10}
      }
    }
  end

  setup do
    stub(@rds, :get, fn _departures, @now -> [] end)
    stub(@cache, :disabled_modes, fn -> [] end)
    :ok
  end

  describe "departures_instances/2" do
    defp build_config(sections_or_route_ids) do
      %Screen{
        app_params: %BusShelter{
          departures: build_departures_config(sections_or_route_ids),
          header: nil,
          footer: nil,
          alerts: nil
        },
        vendor: nil,
        device_id: nil,
        name: nil,
        app_id: :bus_shelter_v2
      }
    end

    defp build_departures_config(sections_or_route_ids) do
      %DeparturesConfig{
        sections:
          case sections_or_route_ids do
            [%Section{} | _] = sections ->
              sections

            route_ids ->
              Enum.map(
                route_ids,
                &%Section{query: %Query{params: %Query.Params{route_ids: [&1]}}}
              )
          end
      }
    end

    test "returns DeparturesNoData when all sections come back empty or with errors" do
      config = build_config(["route_A"])

      expect(@rds, :get, fn _departures, @now ->
        [:error, {:ok, []}, :error]
      end)

      assert [%DeparturesNoData{}] = RealtimeDepartures.departures_instances(config, @now)
    end

    test "returns DeparturesNoData when all sections are sections we don't support" do
      config = build_config(["route_A"])

      expect(@rds, :get, fn _departures, @now ->
        [
          {:ok,
           [
             no_service("stop_id_one", "line_id_one", "test_headsign_one"),
             service_ended(
               "stop_id_two",
               "line_id_two",
               "test_headsign_two",
               build_schedule("route_two", "line_id_two")
             ),
             headways(
               "stop_id_three",
               "line_id_three",
               "test_headsign_three",
               "route_id_three",
               "direction_zero",
               0
             )
           ]}
        ]
      end)

      assert [%DeparturesNoData{}] = RealtimeDepartures.departures_instances(config, @now)
    end

    test "returns NormalSection with departures when RDS returns supported and unsupported states" do
      config = build_config(["route_A"])

      schedule = build_schedule("route_two", "line_id_two")
      departure = build_departure("r1", 0, :bus)

      expect(@rds, :get, fn _departures, @now ->
        [
          {:ok,
           [
             countdowns("stop_id_one", "line_id_one", "headsign", [departure]),
             first_trip("stop_id_two", "line_id_two", "test_headsign_two", schedule),
             no_service("stop_id_three", "line_id_three", "test_headsign_three")
           ]}
        ]
      end)

      assert [
               %DeparturesWidget{
                 now: @now,
                 order: 0,
                 screen: ^config,
                 sections: [
                   %NormalSection{
                     header: %Header{},
                     grouping_type: :time,
                     layout: %Layout{},
                     rows: [^departure, %Departure{schedule: ^schedule, prediction: nil}]
                   }
                 ]
               }
             ] = RealtimeDepartures.departures_instances(config, @now)
    end

    test "returns NormalSection with departures and no data sections when we have one section with supported rows and one without" do
      config = build_config(["route_A", "route_B"])

      schedule = build_schedule("route_two", "line_id_two")
      departure = build_departure("r1", 0, :bus)

      expect(@rds, :get, fn _departures, @now ->
        [
          {:ok,
           [
             countdowns("stop_id_one", "line_id_one", "headsign", [departure]),
             first_trip("stop_id_two", "line_id_two", "test_headsign_two", schedule),
             no_service("stop_id_three", "line_id_three", "test_headsign_three")
           ]},
          {:ok,
           [
             no_service("stop_id_three", "line_id_three", "test_headsign_three")
           ]}
        ]
      end)

      assert [
               %DeparturesWidget{
                 now: @now,
                 order: 0,
                 screen: ^config,
                 sections: [
                   %NormalSection{
                     header: %Header{},
                     grouping_type: :time,
                     layout: %Layout{},
                     rows: [^departure, %Departure{schedule: ^schedule, prediction: nil}]
                   },
                   %NormalSection{
                     header: %Header{},
                     grouping_type: :time,
                     layout: %Layout{},
                     rows: [
                       %ScreensConfig.FreeTextLine{
                         icon: :bus,
                         text: ["No departures currently available"]
                       }
                     ]
                   }
                 ]
               }
             ] = RealtimeDepartures.departures_instances(config, @now)
    end

    test "returns NormalSection to display if it's header only, even if other sections have no data" do
      config =
        build_config([
          %Section{
            header: %Header{title: "Test Header"},
            header_only: true,
            query: %Query{params: %Query.Params{route_ids: []}}
          },
          %Section{query: %Query{params: %Query.Params{route_ids: ["route_one"]}}}
        ])

      expect(@rds, :get, fn _departures, @now ->
        [
          {:ok, []},
          {:ok,
           [
             no_service("stop_id_three", "line_id_three", "test_headsign_three")
           ]}
        ]
      end)

      assert [
               %DeparturesWidget{
                 now: @now,
                 order: 0,
                 screen: ^config,
                 sections: [
                   %NormalSection{header: %Header{title: "Test Header"}, rows: []},
                   %NormalSection{
                     header: %Header{},
                     grouping_type: :time,
                     layout: %Layout{},
                     rows: [
                       %ScreensConfig.FreeTextLine{
                         icon: :bus,
                         text: ["No departures currently available"]
                       }
                     ]
                   }
                 ]
               }
             ] = RealtimeDepartures.departures_instances(config, @now)
    end

    test "returns DeparturesNoData if the mode for the screen type is devops-disabled" do
      config = build_config(["route_A"])

      expect(@cache, :disabled_modes, fn -> [:bus] end)

      assert [%DeparturesNoData{screen: ^config, show_alternatives?: false}] =
               RealtimeDepartures.departures_instances(config, @now)
    end

    test "post process filters departures by time when a section has a max_minutes" do
      config =
        build_config([
          %Section{
            query: %Query{params: %Query.Params{stop_ids: ["S"]}},
            filters: %Filters{max_minutes: 10}
          }
        ])

      included_departures = [
        build_departure("1", 0, nil, DateTime.add(@now, 8, :minute)),
        build_departure("1", 0, nil, DateTime.add(@now, 9, :minute))
      ]

      excluded_departure = [
        build_departure("1", 0, nil, DateTime.add(@now, 11, :minute))
      ]

      all_departures = included_departures ++ excluded_departure

      expect(@rds, :get, fn _departures, @now ->
        [
          {:ok,
           [
             countdowns("stop_id_one", "line_id_one", "headsign", all_departures)
           ]}
        ]
      end)

      assert [%DeparturesWidget{sections: [%NormalSection{rows: ^included_departures}]}] =
               RealtimeDepartures.departures_instances(config, @now)
    end

    test "post process filters departures with included route-directions" do
      config =
        build_config([
          %Section{
            query: %Query{params: %Query.Params{stop_ids: ["S"]}},
            filters: %Filters{
              route_directions: %RouteDirections{
                action: :include,
                targets: [
                  %RouteDirection{route_id: "39", direction_id: 0},
                  %RouteDirection{route_id: "41", direction_id: 0}
                ]
              }
            }
          }
        ])

      included_departure = build_departure("41", 0)
      all_departures = [build_departure("41", 1), included_departure, build_departure("1", 1)]

      expect(@rds, :get, fn _departures, @now ->
        [
          {:ok,
           [
             countdowns("bus_route", "line_id_one", "headsign", all_departures)
           ]}
        ]
      end)

      assert [%DeparturesWidget{sections: [%NormalSection{rows: [^included_departure]}]}] =
               RealtimeDepartures.departures_instances(config, @now)
    end

    test "post process filters departures for sections configured as bidirectional" do
      config =
        build_config([
          %Section{query: %Query{params: %Query.Params{route_ids: ["A"]}}, bidirectional: true},
          %Section{query: %Query{params: %Query.Params{route_ids: ["B"]}}}
        ])

      departure_a_0 = build_departure("A", 0)
      departure_a_1 = build_departure("A", 1)
      departure_b_0 = build_departure("B", 0)

      expect(@rds, :get, fn _departures, @now ->
        [
          {:ok,
           [
             countdowns("bus_route", "line_id_one", "headsign", [
               departure_a_0,
               departure_a_0,
               departure_a_1,
               departure_a_0
             ])
           ]},
          {:ok,
           [countdowns("bus_route", "line_id_one", "headsign", [departure_b_0, departure_b_0])]}
        ]
      end)

      assert [
               %DeparturesWidget{
                 screen: ^config,
                 sections: [
                   %{rows: [^departure_a_0, ^departure_a_1]},
                   %{rows: [^departure_b_0, ^departure_b_0]}
                 ]
               }
             ] = RealtimeDepartures.departures_instances(config, @now)
    end
  end
end
