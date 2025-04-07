defmodule Screens.V2.CandidateGenerator.Elevator.ClosuresTest do
  use ExUnit.Case, async: true

  alias Screens.Alerts.Alert
  alias Screens.Elevator
  alias Screens.Facilities.Facility
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
  @stop injected(Stop)

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

  @alert_opts [activity: "USING_WHEELCHAIR"]

  setup do
    stub(@alert, :fetch, fn @alert_opts -> {:ok, []} end)
    stub(@elevator, :get, fn id -> build_elevator(id) end)
    stub(@facility, :fetch_by_id, fn id -> {:ok, build_facility(id)} end)
    stub(@route, :fetch, fn _params -> {:ok, [%Route{id: "Red", type: :subway}]} end)

    stub(@stop, :fetch_parent_station_name_map, fn ->
      {:ok, %{"place-test" => "Place Test"}}
    end)

    {:ok, %{now: DateTime.utc_now()}}
  end

  defp build_alert(fields) do
    struct!(%Alert{active_period: [{DateTime.utc_now(), nil}], effect: :elevator_closure}, fields)
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
        stop: %Stop{id: "place-test"}
      },
      fields
    )
  end

  describe "header and footer" do
    test "have no variant when current elevator is not closed", %{now: now} do
      expect(@stop, :fetch_parent_station_name_map, fn ->
        {:ok, %{"place-haecl" => "Haymarket"}}
      end)

      expect(@alert, :fetch, fn @alert_opts ->
        alerts = [
          build_alert(informed_entities: [%{stop: "place-haecl", facility: build_facility("f1")}])
        ]

        {:ok, alerts}
      end)

      assert [
               _elevator_closures,
               %NormalHeader{screen: @screen, text: "Elevator 111", time: ^now, variant: nil},
               %Footer{screen: @screen, variant: nil}
             ] = Generator.elevator_status_instances(@screen, now)
    end

    test "have closed variant when current elevator is closed", %{now: now} do
      expect(@alert, :fetch, fn @alert_opts ->
        alerts = [
          build_alert(informed_entities: [%{stop: "place-test", facility: build_facility("111")}])
        ]

        {:ok, alerts}
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
        alerts = [
          build_alert(informed_entities: [%{stop: "place-test", facility: build_facility("111")}])
        ]

        {:ok, alerts}
      end)

      app_params = @screen.app_params

      assert [%ElevatorAlternatePath{app_params: ^app_params} | _] =
               Generator.elevator_status_instances(@screen, now)
    end
  end

  describe "closure list widget" do
    test "is returned based on currently-active elevator alerts", %{now: now} do
      expect(@alert, :fetch, fn @alert_opts ->
        active_period = {DateTime.add(now, -1, :day), DateTime.add(now, 1, :day)}
        upcoming_period = {DateTime.add(now, 1, :day), DateTime.add(now, 3, :day)}

        alerts = [
          build_alert(
            active_period: [active_period],
            informed_entities: [
              %{stop: "place-test", facility: build_facility("f1", short_name: "Test 1")}
            ]
          ),
          build_alert(
            active_period: [upcoming_period],
            informed_entities: [%{stop: "place-test", facility: build_facility("f2")}]
          ),
          build_alert(
            effect: :detour,
            active_period: [active_period],
            informed_entities: [%{stop: "place-test", facility: build_facility("f3")}]
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
      expect(@stop, :fetch_parent_station_name_map, fn ->
        {:ok, %{"place-haecl" => "Haymarket"}}
      end)

      expect(@route, :fetch, 2, fn
        %{stop_id: "place-haecl"} ->
          {:ok, [%Route{id: "Orange", type: :subway}]}

        %{stop_id: "place-test"} ->
          {:ok, [%Route{id: "Red", type: :subway}]}
      end)

      expect(@alert, :fetch, fn @alert_opts ->
        alerts = [
          build_alert(
            informed_entities: [
              %{stop: "place-haecl", facility: build_facility("f1", short_name: "Test 1")}
            ]
          ),
          build_alert(
            informed_entities: [
              %{stop: "place-haecl", facility: build_facility("f2", short_name: "Test 2")}
            ]
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
                     summary: {:other, "Visit mbta.com/elevators for more info"}
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
        alerts = [
          build_alert(
            informed_entities: [%{stop: "place-other", facility: build_facility("222")}]
          )
        ]

        {:ok, alerts}
      end)

      assert [%ElevatorClosures{stations_with_closures: :nearby_redundancy} | _] =
               Generator.elevator_status_instances(@screen, now)
    end

    test "filters out alerts with no facilities or more than one facility", %{now: now} do
      expect(@alert, :fetch, fn @alert_opts ->
        alerts = [
          build_alert(informed_entities: [%{stop: "place-haecl", facility: nil}]),
          build_alert(
            informed_entities: [
              %{stop: "place-haecl", facility: build_facility("f1")},
              %{stop: "place-haecl", facility: build_facility("f2")}
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
      expect(@stop, :fetch_parent_station_name_map, fn ->
        {:ok,
         %{
           "place-test" => "This Station",
           "place-test-redundancy" => "Other With Redundancy",
           "place-test-no-redundancy" => "Other No Redundancy"
         }}
      end)

      stub(@route, :fetch, fn _ -> {:ok, [%Route{id: "Red", type: :subway}]} end)

      stub(@elevator, :get, fn
        "112" -> build_elevator("112", exiting_redundancy: :nearby)
        "222" -> build_elevator("222", exiting_redundancy: :nearby)
        "333" -> build_elevator("333", exiting_redundancy: :in_station)
      end)

      expect(@alert, :fetch, fn @alert_opts ->
        alerts = [
          build_alert(
            informed_entities: [
              %{
                stop: "place-test",
                facility: build_facility("112", short_name: "In Station Elevator")
              }
            ]
          ),
          build_alert(
            informed_entities: [
              %{
                stop: "place-test-redundancy",
                facility: build_facility("222", short_name: "Other With Redundancy")
              }
            ]
          ),
          build_alert(
            informed_entities: [
              %{
                stop: "place-test-no-redundancy",
                facility: build_facility("333", short_name: "Other Without Redundancy")
              }
            ]
          )
        ]

        {:ok, alerts}
      end)

      assert [
               %ElevatorClosures{
                 stations_with_closures: [
                   %ElevatorClosures.Station{
                     id: "place-test",
                     name: "This Station",
                     route_icons: [%{type: :text, text: "RL", color: :red}],
                     closures: [%Closure{id: "112", name: "In Station Elevator"}]
                   },
                   %ElevatorClosures.Station{
                     id: "place-test-no-redundancy",
                     name: "Other No Redundancy",
                     route_icons: [%{type: :text, text: "RL", color: :red}],
                     closures: [%Closure{id: "333", name: "Other Without Redundancy"}]
                   }
                 ]
               }
               | _
             ] = Generator.elevator_status_instances(@screen, now)
    end

    test "generates backup route summaries based on exiting redundancy", %{now: now} do
      stub(@elevator, :get, fn
        "1" -> build_elevator("1", exiting_redundancy: :in_station, exiting_summary: "es1")
        "2" -> build_elevator("2", exiting_redundancy: :other, exiting_summary: "es2")
        "3" -> build_elevator("3", alternate_ids: ["alt"], exiting_redundancy: :nearby)
        "alt" -> build_elevator("alt", exiting_redundancy: :nearby)
      end)

      expect(@stop, :fetch_parent_station_name_map, fn ->
        {:ok,
         %{
           "place-1" => "one",
           "place-2" => "two",
           "place-3" => "three",
           "place-4" => "four"
         }}
      end)

      expect(@alert, :fetch, fn @alert_opts ->
        alerts = [
          # backup in station
          build_alert(informed_entities: [%{stop: "place-1", facility: build_facility("1")}]),
          # other with exiting summary
          build_alert(informed_entities: [%{stop: "place-2", facility: build_facility("2")}]),
          # despite having "nearby" redundancy, should not be filtered out, because its alternate
          # elevator is also down
          build_alert(informed_entities: [%{stop: "place-3", facility: build_facility("3")}]),
          # somewhat unrealistically, place elevator 3's "nearby" alternate at a different
          # station, so they aren't combined
          build_alert(informed_entities: [%{stop: "place-4", facility: build_facility("alt")}])
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
                     # TEMP: currently not using exiting summaries, see implementation for details
                     summary: {:other, "Visit mbta.com/elevators for more info"}
                   },
                   %ElevatorClosures.Station{
                     id: "place-3",
                     closures: [%Closure{id: "3"}],
                     summary: {:other, "Visit mbta.com/elevators for more info"}
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

      expect(@stop, :fetch_parent_station_name_map, fn ->
        {:ok, %{"place-1" => "one", "place-2" => "two"}}
      end)

      stub(@facility, :fetch_by_id, fn id ->
        {
          :ok,
          build_facility(id,
            stop: %Stop{
              id:
                case id do
                  "1" -> "place-1"
                  "2" -> "place-2"
                  "alt" -> "place-1"
                end
            }
          )
        }
      end)

      expect(@alert, :fetch, fn @alert_opts ->
        alerts = [
          build_alert(informed_entities: [%{stop: "place-1", facility: build_facility("1")}]),
          # don't use special text when "this" is the backup for a closure at another station
          build_alert(informed_entities: [%{stop: "place-2", facility: build_facility("2")}])
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
                     summary: {:other, "Visit mbta.com/elevators for more info"}
                   }
                 ]
               }
               | _
             ] = Generator.elevator_status_instances(screen, now)
    end

    test "omits route pills on closures when there is a routes API error", %{now: now} do
      expect(@route, :fetch, fn %{stop_id: "place-test"} -> :error end)

      expect(@alert, :fetch, fn @alert_opts ->
        alerts = [
          build_alert(informed_entities: [%{stop: "place-test", facility: build_facility("f1")}])
        ]

        {:ok, alerts}
      end)

      assert [
               %ElevatorClosures{
                 stations_with_closures: [
                   %ElevatorClosures.Station{
                     id: "place-test",
                     name: "Place Test",
                     closures: [%Closure{id: "f1"}]
                   }
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
          build_alert(
            active_period: [
              {dt(~D[2025-01-05], ~T[03:00:00]), dt(~D[2025-01-07], ~T[02:59:00])},
              {dt(~D[2025-02-01], ~T[03:00:00]), dt(~D[2025-02-02], ~T[02:59:00])}
            ],
            informed_entities: [%{stop: "place-test", facility: build_facility("111")}]
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
          build_alert(
            active_period: [{dt(~D[2025-01-05], ~T[03:00:00]), dt(~D[2025-01-07], ~T[02:59:00])}],
            informed_entities: [%{stop: "place-test", facility: build_facility("111")}]
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
