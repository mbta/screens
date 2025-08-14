defmodule Screens.V2.CandidateGenerator.Elevator.ClosuresTest do
  use ExUnit.Case, async: true

  alias Screens.Alerts.Alert
  alias Screens.Elevator
  alias Screens.Facilities.Facility
  alias Screens.RoutePatterns.RoutePattern
  alias Screens.Routes.Route
  alias Screens.Stops.Stop
  alias Screens.V2.CandidateGenerator.Elevator.Closures, as: Generator
  alias Screens.V2.WidgetInstance.Elevator.Closure
  alias Screens.V2.WidgetInstance.{ElevatorAlternatePath, ElevatorClosures, Footer, NormalHeader}
  alias ScreensConfig.Screen
  alias ScreensConfig.Screen.Elevator, as: ElevatorConfig

  import ExUnit.CaptureLog
  import Screens.Inject
  import Mox
  setup :verify_on_exit!

  @alert injected(Alert)
  @elevator injected(Elevator)
  @facility injected(Screens.Facilities.Facility)
  @route injected(Route)
  @route_pattern injected(RoutePattern)

  @app_params %ElevatorConfig{
    elevator_id: "111",
    accessible_path_direction_arrow: :n,
    alternate_direction_text: "Test"
  }

  @screen %Screen{
    app_id: :elevator_v2,
    app_params: @app_params,
    device_id: "test",
    name: "test",
    vendor: :mimo
  }

  @alert_opts [activities: [:using_wheelchair], include_all?: true]

  setup do
    stub(@alert, :fetch, fn @alert_opts -> {:ok, []} end)
    stub(@elevator, :get, fn id -> build_elevator(id) end)
    stub(@facility, :fetch_by_id, fn id -> {:ok, build_facility(id)} end)
    stub(@route, :fetch, fn _params -> {:ok, [%Route{id: "Red", type: :subway}]} end)
    stub(@route_pattern, :fetch, fn _params -> {:ok, []} end)

    {:ok, %{now: DateTime.utc_now()}}
  end

  defp build_alert(fields) do
    struct!(%Alert{active_period: [{DateTime.utc_now(), nil}], effect: :elevator_closure}, fields)
  end

  defp build_facility_alert(facility_id, station_id, opts \\ []) do
    {opts, alert_fields} =
      Keyword.split(opts, ~w[child_stop_ids facility_name facility_excludes station_name]a)

    facility_name = Keyword.get(opts, :facility_name, "Elevator #{facility_id}")
    facility_excludes = Keyword.get(opts, :facility_excludes, [])
    station_name = Keyword.get(opts, :station_name, "#{station_id} Station")
    child_stop_ids = Keyword.get(opts, :child_stop_ids, [])

    alert_fields
    |> Keyword.merge(
      informed_entities: [
        %{
          facility:
            build_facility(facility_id,
              excludes_stop_ids: facility_excludes,
              short_name: facility_name,
              stop: %Stop{
                id: station_id,
                name: station_name,
                location_type: 1,
                child_stops: Enum.map(child_stop_ids, &%Stop{id: &1})
              }
            )
        }
      ]
    )
    |> build_alert()
  end

  defp build_elevator(id, fields \\ []) do
    struct!(
      %Elevator{
        id: id,
        alternate_ids: [],
        entering_redundancy: :in_station,
        exiting_redundancy: :in_station,
        exiting_summary: "Accessible route available"
      },
      fields
    )
  end

  defp build_facility(id, fields \\ []) do
    struct!(
      %Facility{
        id: id,
        long_name: "long",
        short_name: "short",
        type: :elevator,
        stop: %Stop{id: "place-test", location_type: 1, child_stops: []}
      },
      fields
    )
  end

  defp build_route_pattern(direction_id, child_and_parent_ids) do
    %RoutePattern{
      direction_id: direction_id,
      stops:
        Enum.map(child_and_parent_ids, fn {child_id, parent_id} ->
          %Stop{id: child_id, parent_station: %Stop{id: parent_id, location_type: 1}}
        end)
    }
  end

  describe "header and footer" do
    test "have no variant when current elevator is not closed", %{now: now} do
      expect(@alert, :fetch, fn @alert_opts ->
        {:ok, [build_facility_alert("f1", "place-haecl")]}
      end)

      assert [
               _elevator_closures,
               %NormalHeader{screen: @screen, text: "Elevator 111", time: ^now, variant: nil},
               %Footer{screen: @screen, variant: nil}
             ] = Generator.elevator_status_instances(@screen, now)
    end

    test "have closed variant when current elevator is closed", %{now: now} do
      expect(@alert, :fetch, fn @alert_opts ->
        {:ok, [build_facility_alert("111", "place-test")]}
      end)

      assert [_current_closed, %NormalHeader{variant: :closed}, %Footer{variant: :closed}] =
               Generator.elevator_status_instances(@screen, now)
    end

    test "have footer not displayed and header with no variant when all elevators are working", %{
      now: now
    } do
      assert [
               _elevator_closures,
               %NormalHeader{screen: @screen, text: "Elevator 111", time: ^now, variant: nil}
             ] = Generator.elevator_status_instances(@screen, now)
    end
  end

  describe "alternate path widget" do
    test "is returned when the screen's elevator is closed", %{now: now} do
      expect(@alert, :fetch, fn @alert_opts ->
        {:ok, [build_facility_alert("111", "place-test")]}
      end)

      app_params = @screen.app_params

      assert [%ElevatorAlternatePath{app_params: ^app_params} | _] =
               Generator.elevator_status_instances(@screen, now)
    end
  end

  describe "closure list widget" do
    @fallback_summary {:other, "Visit mbta.com/elevators for more info"}

    test "is returned based on currently-active elevator alerts", %{now: now} do
      expect(@alert, :fetch, fn @alert_opts ->
        active_period = {DateTime.add(now, -1, :day), DateTime.add(now, 1, :day)}
        upcoming_period = {DateTime.add(now, 1, :day), DateTime.add(now, 3, :day)}

        alerts = [
          build_facility_alert("f1", "place-test",
            facility_name: "Test 1",
            station_name: "Place Test",
            active_period: [active_period]
          ),
          build_facility_alert("f2", "place-test", active_period: [upcoming_period]),
          build_facility_alert("f3", "place-test",
            active_period: [active_period],
            effect: :detour
          )
        ]

        {:ok, alerts}
      end)

      expected_closures = %ElevatorClosures{
        app_params: @screen.app_params,
        now: now,
        station_id: "place-test",
        stations_with_closures: [
          %ElevatorClosures.Station{
            id: "place-test",
            name: "Place Test",
            route_icons: [%{type: :text, text: "RL", color: :red}],
            closures: [%Closure{id: "f1", name: "Test 1"}],
            summary: {:inside, "Accessible route available"}
          }
        ]
      }

      assert hd(Generator.elevator_status_instances(@screen, now)) == expected_closures
    end

    test "groups multiple outside closures by station", %{now: now} do
      expect(@route, :fetch, fn %{stop_id: "place-haecl"} ->
        {:ok, [%Route{id: "Orange", type: :subway}]}
      end)

      expect(@alert, :fetch, fn @alert_opts ->
        alerts = [
          build_facility_alert("f1", "place-haecl",
            facility_name: "Test 1",
            station_name: "Haymarket"
          ),
          build_facility_alert("f2", "place-haecl",
            facility_name: "Test 2",
            station_name: "Haymarket"
          )
        ]

        {:ok, alerts}
      end)

      assert [
               %ElevatorClosures{
                 stations_with_closures: [
                   %ElevatorClosures.Station{
                     id: "place-haecl",
                     name: "Haymarket",
                     route_icons: [%{type: :text, text: "OL", color: :orange}],
                     closures: [
                       %Closure{id: "f1", name: "Test 1"},
                       %Closure{id: "f2", name: "Test 2"}
                     ],
                     summary: @fallback_summary
                   }
                 ]
               }
               | _
             ] = Generator.elevator_status_instances(@screen, now)
    end

    test "uses :no_closures when all elevators are working", %{now: now} do
      assert [%ElevatorClosures{stations_with_closures: :no_closures} | _] =
               Generator.elevator_status_instances(@screen, now)
    end

    test "uses :nearby_redundancy when all closed elevators have nearby redundancy", %{now: now} do
      stub(@elevator, :get, fn
        "111" -> build_elevator("111")
        "222" -> build_elevator("222", exiting_redundancy: :nearby)
      end)

      expect(@alert, :fetch, fn @alert_opts ->
        {:ok, [build_facility_alert("222", "place-other")]}
      end)

      assert [%ElevatorClosures{stations_with_closures: :nearby_redundancy} | _] =
               Generator.elevator_status_instances(@screen, now)
    end

    test "filters out alerts with no facilities or more than one facility", %{now: now} do
      expect(@alert, :fetch, fn @alert_opts ->
        alerts = [
          build_alert(informed_entities: [%{facility: nil}]),
          build_alert(
            informed_entities: [
              %{facility: build_facility("f1")},
              %{facility: build_facility("f2")}
            ]
          )
        ]

        {:ok, alerts}
      end)

      logs =
        capture_log([level: :warning], fn ->
          assert [%ElevatorClosures{stations_with_closures: :no_closures} | _] =
                   Generator.elevator_status_instances(@screen, now)
        end)

      assert logs =~ "elevator_closure_affects_multiple"
    end

    test "filters out alerts at other stations with nearby exiting redundancy", %{now: now} do
      stub(@route, :fetch, fn _ -> {:ok, [%Route{id: "Red", type: :subway}]} end)

      stub(@elevator, :get, fn
        "112" -> build_elevator("112", exiting_redundancy: :nearby)
        "222" -> build_elevator("222", exiting_redundancy: :nearby)
        "333" -> build_elevator("333", exiting_redundancy: :in_station)
      end)

      expect(@alert, :fetch, fn @alert_opts ->
        alerts = [
          build_facility_alert("112", "place-test", station_name: "This Station"),
          build_facility_alert("222", "place-test-with", station_name: "Other With Redundancy"),
          build_facility_alert("333", "place-test-without", station_name: "Other No Redundancy")
        ]

        {:ok, alerts}
      end)

      assert [
               %ElevatorClosures{
                 stations_with_closures: [
                   %ElevatorClosures.Station{
                     id: "place-test",
                     name: "This Station",
                     closures: [%Closure{id: "112"}]
                   },
                   %ElevatorClosures.Station{
                     id: "place-test-without",
                     name: "Other No Redundancy",
                     closures: [%Closure{id: "333"}]
                   }
                 ]
               }
               | _
             ] = Generator.elevator_status_instances(@screen, now)
    end

    test "generates backup route summaries based on exiting redundancy", %{now: now} do
      stub(@elevator, :get, fn
        "1" -> build_elevator("1", exiting_redundancy: :in_station, exiting_summary: "es1")
        "2" -> build_elevator("2", alternate_ids: ["alt"], exiting_redundancy: :nearby)
        "alt" -> build_elevator("alt", exiting_redundancy: :nearby)
      end)

      expect(@alert, :fetch, fn @alert_opts ->
        alerts = [
          # backup in station
          build_facility_alert("1", "place-1"),
          # despite having "nearby" redundancy, should not be filtered out, because its alternate
          # elevator is also down
          build_facility_alert("2", "place-2"),
          # has "nearby" redundancy, so will be filtered out
          build_facility_alert("alt", "place-2")
        ]

        {:ok, alerts}
      end)

      assert [
               %ElevatorClosures{
                 stations_with_closures: [
                   %ElevatorClosures.Station{
                     id: "place-1",
                     closures: [%Closure{id: "1"}],
                     summary: {:inside, "es1"}
                   },
                   %ElevatorClosures.Station{
                     id: "place-2",
                     closures: [%Closure{id: "2"}],
                     summary: @fallback_summary
                   }
                 ]
               }
               | _
             ] = Generator.elevator_status_instances(@screen, now)
    end

    test "uses a different summary when the screen's elevator is the backup", %{now: now} do
      stub(@elevator, :get, fn
        "1" ->
          build_elevator("1",
            alternate_ids: ["alt"],
            exiting_redundancy: :nearby,
            exiting_summary: "es1"
          )

        "2" ->
          build_elevator("2", alternate_ids: ["alt"], exiting_redundancy: :other)

        "alt" ->
          build_elevator("alt")
      end)

      expect(@facility, :fetch_by_id, fn "alt" ->
        {:ok, build_facility("alt", stop: %Stop{id: "place-1"})}
      end)

      expect(@alert, :fetch, fn @alert_opts ->
        alerts = [
          build_facility_alert("1", "place-1"),
          # don't use special text when "this" is the backup for a closure at another station
          build_facility_alert("2", "place-2")
        ]

        {:ok, alerts}
      end)

      screen = %{@screen | app_params: %{@app_params | elevator_id: "alt"}}

      assert [
               %ElevatorClosures{
                 stations_with_closures: [
                   %ElevatorClosures.Station{
                     id: "place-1",
                     closures: [%Closure{id: "1"}],
                     summary: {:inside, "This is the backup elevator"}
                   },
                   %ElevatorClosures.Station{
                     id: "place-2",
                     closures: [%Closure{id: "2"}],
                     summary: @fallback_summary
                   }
                 ]
               }
               | _
             ] = Generator.elevator_status_instances(screen, now)
    end

    test "uses custom summaries for closures downstream of the screen's station", %{now: now} do
      stub(@elevator, :get, fn
        "upstream" ->
          build_elevator("upstream", exiting_redundancy: :other)

        "here" ->
          build_elevator("here", exiting_redundancy: :other)

        "downstream" ->
          build_elevator("downstream", exiting_redundancy: :other, exiting_summary: "es1")

        "elsewhere" ->
          build_elevator("elsewhere", exiting_redundancy: :other)
      end)

      expect(
        @route_pattern,
        :fetch,
        fn %{canonical?: true, stop_ids: ~w[dir0-p1 dir0-p2 dir0-p3 dir1-p2 dir1-p4]} ->
          {
            :ok,
            [
              build_route_pattern(0, [
                {"dir0-p1", "place-1"},
                {"dir0-p2", "place-2"},
                {"dir0-p3", "place-3"},
                {"dir0-p4", "place-4"}
              ]),
              build_route_pattern(1, [
                {"dir1-p4", "place-4"},
                {"dir1-p3", "place-3"},
                {"dir1-p2", "place-2"},
                {"dir1-p1", "place-1"}
              ])
            ]
          }
        end
      )

      expect(@facility, :fetch_by_id, fn "111" ->
        {
          :ok,
          build_facility("111",
            stop: %Stop{
              id: "place-2",
              location_type: 1,
              child_stops: [%Stop{id: "dir0-p2"}, %Stop{id: "dir1-p2"}]
            }
          )
        }
      end)

      expect(@alert, :fetch, fn @alert_opts ->
        alerts = [
          build_facility_alert("upstream", "place-1",
            child_stop_ids: ~w[dir0-p1 dir1-p1],
            facility_excludes: ~w[dir1-p1]
          ),
          build_facility_alert("here", "place-2", child_stop_ids: ~w[dir0-p2 dir1-p2]),
          build_facility_alert("downstream", "place-3",
            child_stop_ids: ~w[dir0-p3 dir1-p3],
            facility_excludes: ~w[dir1-p3]
          ),
          # served child stop not reachable from the screen's station without reversing direction
          build_facility_alert("elsewhere", "place-4",
            child_stop_ids: ~w[dir0-p4 dir1-p4],
            facility_excludes: ~w[dir0-p4]
          )
        ]

        {:ok, alerts}
      end)

      assert [
               %ElevatorClosures{
                 stations_with_closures: [
                   %ElevatorClosures.Station{
                     id: "place-1",
                     closures: [%Closure{id: "upstream"}],
                     summary: @fallback_summary
                   },
                   %ElevatorClosures.Station{
                     id: "place-2",
                     closures: [%Closure{id: "here"}],
                     summary: @fallback_summary
                   },
                   %ElevatorClosures.Station{
                     id: "place-3",
                     closures: [%Closure{id: "downstream"}],
                     summary: {:other, "es1"}
                   },
                   %ElevatorClosures.Station{
                     id: "place-4",
                     closures: [%Closure{id: "elsewhere"}],
                     summary: @fallback_summary
                   }
                 ]
               }
               | _
             ] = Generator.elevator_status_instances(@screen, now)
    end

    test "uses fallback summary when there is a route patterns API error", %{now: now} do
      expect(@route_pattern, :fetch, fn _params -> :error end)

      expect(@alert, :fetch, fn @alert_opts ->
        {:ok, [build_facility_alert("f1", "place-1")]}
      end)

      expect(@elevator, :get, fn "f1" -> build_elevator("f1", exiting_redundancy: :other) end)

      assert [
               %ElevatorClosures{
                 stations_with_closures: [
                   %ElevatorClosures.Station{id: "place-1", summary: @fallback_summary}
                 ]
               }
               | _
             ] = Generator.elevator_status_instances(@screen, now)
    end

    test "omits route pills on closures when there is a routes API error", %{now: now} do
      expect(@route, :fetch, fn %{stop_id: "place-test"} -> :error end)

      expect(@alert, :fetch, fn @alert_opts ->
        {:ok, [build_facility_alert("f1", "place-test")]}
      end)

      assert [
               %ElevatorClosures{
                 stations_with_closures: [
                   %ElevatorClosures.Station{id: "place-test", closures: [%Closure{id: "f1"}]}
                 ]
               }
               | _
             ] = Generator.elevator_status_instances(@screen, now)
    end
  end

  describe "upcoming closure" do
    defp dt(date, time), do: DateTime.new!(date, time, "America/New_York")

    test "is included when the screen's elevator has a planned closure" do
      now = dt(~D[2025-01-01], ~T[09:00:00])

      expect(@alert, :fetch, fn @alert_opts ->
        alerts = [
          build_facility_alert("111", "place-test",
            active_period: [
              {dt(~D[2025-01-05], ~T[04:00:00]), dt(~D[2025-01-07], ~T[03:59:59])},
              {dt(~D[2025-02-01], ~T[04:00:00]), dt(~D[2025-02-02], ~T[03:59:59])}
            ]
          )
        ]

        {:ok, alerts}
      end)

      expect(@elevator, :get, fn "111" ->
        build_elevator("111", entering_redundancy: :in_station)
      end)

      assert [
               %ElevatorClosures{
                 upcoming_closure: %ElevatorClosures.Upcoming{
                   period: {~D[2025-01-05], ~D[2025-01-06]},
                   summary: "An accessible route will be available."
                 }
               }
               | _
             ] = Generator.elevator_status_instances(@screen, now)
    end

    test "is not included when the screen's elevator has nearby redundancy" do
      now = dt(~D[2025-01-01], ~T[09:00:00])

      expect(@alert, :fetch, fn @alert_opts ->
        alerts = [
          build_facility_alert("111", "place-test",
            active_period: [{dt(~D[2025-01-05], ~T[03:00:00]), dt(~D[2025-01-07], ~T[02:59:00])}]
          )
        ]

        {:ok, alerts}
      end)

      expect(@elevator, :get, fn "111" -> build_elevator("111", entering_redundancy: :nearby) end)

      assert [%ElevatorClosures{upcoming_closure: nil} | _] =
               Generator.elevator_status_instances(@screen, now)
    end
  end
end
