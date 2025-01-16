defmodule Screens.V2.CandidateGenerator.Elevator.ClosuresTest do
  use ExUnit.Case, async: true

  alias Screens.Alerts.Alert
  alias Screens.Elevator
  alias Screens.Routes.Route
  alias Screens.Stops.Stop
  alias Screens.V2.CandidateGenerator.Elevator.Closures, as: ElevatorClosures
  alias Screens.V2.WidgetInstance.Elevator.Closure

  alias Screens.V2.WidgetInstance.{
    CurrentElevatorClosed,
    Footer,
    NormalHeader,
    ElevatorClosuresList
  }

  alias ScreensConfig.Screen
  alias ScreensConfig.V2.Elevator, as: ElevatorConfig

  import ExUnit.CaptureLog
  import Screens.Inject
  import Mox
  setup :verify_on_exit!

  @alert injected(Alert)
  @elevator injected(Elevator)
  @facility injected(Screens.Facilities.Facility)
  @route injected(Route)
  @stop injected(Stop)

  setup do
    stub(@elevator, :get, fn id ->
      %Elevator{id: id, alternate_ids: [], redundancy: :in_station}
    end)

    stub(@facility, :fetch_stop_for_facility, fn _facility_id ->
      {:ok, %Stop{id: "place-test"}}
    end)

    :ok
  end

  defp build_alert(fields) do
    struct!(%Alert{active_period: [{DateTime.utc_now(), nil}], effect: :elevator_closure}, fields)
  end

  describe "elevator_status_instances/3" do
    setup do
      config = %ElevatorConfig{
        elevator_id: "111",
        accessible_path_direction_arrow: :n,
        alternate_direction_text: "Test"
      }

      %{
        config: config,
        header_instance: %NormalHeader{
          screen: config,
          icon: nil,
          text: "Elevator 1",
          time: ~U[2020-04-06T10:00:00Z]
        },
        footer_instance: %Footer{screen: config}
      }
    end

    test "Only returns currently-active alerts with effect of :elevator_closure", %{
      config: config,
      header_instance: header_instance,
      footer_instance: footer_instance
    } do
      expect(@stop, :fetch_parent_station_name_map, fn ->
        {:ok, %{"place-test" => "Place Test"}}
      end)

      expect(@route, :fetch, fn %{stop_id: "place-test"} ->
        {:ok, [%Route{id: "Red", type: :subway}]}
      end)

      expect(@alert, :fetch_elevator_alerts_with_facilities, fn ->
        now = DateTime.utc_now()
        active_period = {DateTime.add(now, -1, :day), DateTime.add(now, 1, :day)}
        upcoming_period = {DateTime.add(now, 1, :day), DateTime.add(now, 3, :day)}

        alerts = [
          build_alert(
            active_period: [active_period],
            informed_entities: [
              %{stop: "place-test", facility: %{name: "Test", id: "facility-test"}}
            ]
          ),
          build_alert(
            active_period: [upcoming_period],
            informed_entities: [
              %{stop: "place-test", facility: %{name: "Test 2", id: "facility-test2"}}
            ]
          ),
          build_alert(
            effect: :detour,
            active_period: [active_period],
            informed_entities: [
              %{stop: "place-test", facility: %{name: "Test 3", id: "facility-test3"}}
            ]
          )
        ]

        {:ok, alerts}
      end)

      assert [
               ^header_instance,
               %ElevatorClosuresList{
                 app_params: ^config,
                 stations_with_closures: [
                   %ElevatorClosuresList.Station{
                     id: "place-test",
                     name: "Place Test",
                     route_icons: [%{type: :text, text: "RL", color: :red}],
                     closures: [%Closure{id: "facility-test", name: "Test"}],
                     summary: nil
                   }
                 ],
                 station_id: "place-test"
               },
               ^footer_instance
             ] =
               ElevatorClosures.elevator_status_instances(
                 struct(Screen, app_id: :elevator_v2, app_params: config),
                 header_instance,
                 footer_instance
               )
    end

    test "Groups multiple outside closures by station", %{
      config: config,
      header_instance: header_instance,
      footer_instance: footer_instance
    } do
      expect(@stop, :fetch_parent_station_name_map, fn ->
        {:ok, %{"place-haecl" => "Haymarket"}}
      end)

      expect(@route, :fetch, 2, fn
        %{stop_id: "place-haecl"} ->
          {:ok, [%Route{id: "Orange", type: :subway}]}

        %{stop_id: "place-test"} ->
          {:ok, [%Route{id: "Red", type: :subway}]}
      end)

      expect(@alert, :fetch_elevator_alerts_with_facilities, fn ->
        alerts = [
          build_alert(
            informed_entities: [
              %{stop: "place-haecl", facility: %{name: "Test 1", id: "facility-test-1"}}
            ]
          ),
          build_alert(
            informed_entities: [
              %{stop: "place-haecl", facility: %{name: "Test 2", id: "facility-test-2"}}
            ]
          )
        ]

        {:ok, alerts}
      end)

      assert [
               ^header_instance,
               %ElevatorClosuresList{
                 app_params: ^config,
                 stations_with_closures: [
                   %{
                     id: "place-haecl",
                     name: "Haymarket",
                     route_icons: [%{type: :text, text: "OL", color: :orange}],
                     closures: [
                       %Closure{id: "facility-test-1", name: "Test 1"},
                       %Closure{id: "facility-test-2", name: "Test 2"}
                     ],
                     summary: "Visit mbta.com/alerts for more info"
                   }
                 ]
               },
               ^footer_instance
             ] =
               ElevatorClosures.elevator_status_instances(
                 struct(Screen, app_id: :elevator_v2, app_params: config),
                 header_instance,
                 footer_instance
               )
    end

    test "Filters alerts with no facilities or more than one facility", %{
      config: config,
      header_instance: header_instance,
      footer_instance: footer_instance
    } do
      expect(@stop, :fetch_parent_station_name_map, fn ->
        {:ok, %{"place-haecl" => "Haymarket"}}
      end)

      expect(@route, :fetch, fn _ -> {:ok, [%Route{id: "Red", type: :subway}]} end)

      expect(@alert, :fetch_elevator_alerts_with_facilities, fn ->
        alerts = [
          build_alert(informed_entities: [%{stop: "place-haecl", facility: nil}]),
          build_alert(
            informed_entities: [
              %{stop: "place-haecl", facility: %{name: "Test 2", id: "facility-test-2"}},
              %{stop: "place-haecl", facility: %{name: "Test 2", id: "facility-test-3"}}
            ]
          )
        ]

        {:ok, alerts}
      end)

      logs =
        capture_log([level: :warning], fn ->
          assert [
                   ^header_instance,
                   %ElevatorClosuresList{
                     app_params: ^config,
                     stations_with_closures: []
                   },
                   ^footer_instance
                 ] =
                   ElevatorClosures.elevator_status_instances(
                     struct(Screen, app_id: :elevator_v2, app_params: config),
                     header_instance,
                     footer_instance
                   )
        end)

      assert logs =~ "elevator_closure_affects_multiple"
    end

    test "Filters out alerts at other stations with nearby redundancy", %{
      config: config,
      header_instance: header_instance,
      footer_instance: footer_instance
    } do
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
        "112" -> %Elevator{id: "112", alternate_ids: [], redundancy: :nearby}
        "222" -> %Elevator{id: "222", alternate_ids: [], redundancy: :nearby}
        "333" -> %Elevator{id: "333", alternate_ids: [], redundancy: :in_station}
      end)

      expect(@alert, :fetch_elevator_alerts_with_facilities, fn ->
        alerts = [
          build_alert(
            informed_entities: [
              %{stop: "place-test", facility: %{name: "In Station Elevator", id: "112"}}
            ]
          ),
          build_alert(
            informed_entities: [
              %{
                stop: "place-test-redundancy",
                facility: %{name: "Other With Redundancy", id: "222"}
              }
            ]
          ),
          build_alert(
            informed_entities: [
              %{
                stop: "place-test-no-redundancy",
                facility: %{name: "Other Without Redundancy", id: "333"}
              }
            ]
          )
        ]

        {:ok, alerts}
      end)

      assert [
               ^header_instance,
               %ElevatorClosuresList{
                 app_params: %ScreensConfig.V2.Elevator{
                   elevator_id: "111",
                   alternate_direction_text: "Test",
                   accessible_path_direction_arrow: :n,
                   evergreen_content: [],
                   accessible_path_image_url: nil,
                   accessible_path_image_here_coordinates: %{y: 0, x: 0}
                 },
                 stations_with_closures: [
                   %ElevatorClosuresList.Station{
                     id: "place-test",
                     name: "This Station",
                     route_icons: [%{type: :text, text: "RL", color: :red}],
                     closures: [%Closure{id: "112", name: "In Station Elevator"}]
                   },
                   %ElevatorClosuresList.Station{
                     id: "place-test-no-redundancy",
                     name: "Other No Redundancy",
                     route_icons: [%{type: :text, text: "RL", color: :red}],
                     closures: [%Closure{id: "333", name: "Other Without Redundancy"}]
                   }
                 ],
                 station_id: "place-test"
               },
               ^footer_instance
             ] =
               ElevatorClosures.elevator_status_instances(
                 struct(Screen, app_id: :elevator_v2, app_params: config),
                 header_instance,
                 footer_instance
               )
    end

    test "Generates appropriate backup route summaries", %{
      config: config,
      header_instance: header_instance,
      footer_instance: footer_instance
    } do
      stub(@route, :fetch, fn _ -> {:ok, [%Route{id: "Red", type: :subway}]} end)

      stub(@elevator, :get, fn
        "1" -> %Elevator{id: "1", alternate_ids: [], redundancy: :in_station}
        "2" -> %Elevator{id: "2", alternate_ids: [], redundancy: {:other, "some summary"}}
        "3" -> %Elevator{id: "3", alternate_ids: ["alt"], redundancy: :nearby}
        "alt" -> %Elevator{id: "alt", alternate_ids: [], redundancy: :nearby}
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

      expect(@alert, :fetch_elevator_alerts_with_facilities, fn ->
        alerts = [
          build_alert(
            informed_entities: [
              %{stop: "place-1", facility: %{name: "backup in station", id: "1"}}
            ]
          ),
          build_alert(
            informed_entities: [
              %{stop: "place-2", facility: %{name: "custom backup summary", id: "2"}}
            ]
          ),
          build_alert(
            informed_entities: [
              # despite having "nearby" redundancy, should not be filtered out, because its
              # alternate elevator is also down
              %{stop: "place-3", facility: %{name: "alternate elevator down", id: "3"}}
            ]
          ),
          build_alert(
            informed_entities: [
              # somewhat unrealistically, place elevator 3's "nearby" alternate at a different
              # station, so they aren't combined
              %{stop: "place-4", facility: %{name: "alternate", id: "alt"}}
            ]
          )
        ]

        {:ok, alerts}
      end)

      assert [
               ^header_instance,
               %ElevatorClosuresList{
                 stations_with_closures: [
                   %ElevatorClosuresList.Station{
                     id: "place-1",
                     closures: [%Closure{id: "1"}],
                     summary: nil
                   },
                   %ElevatorClosuresList.Station{
                     id: "place-2",
                     closures: [%Closure{id: "2"}],
                     summary: "some summary"
                   },
                   %ElevatorClosuresList.Station{
                     id: "place-3",
                     closures: [%Closure{id: "3"}],
                     summary: "Visit mbta.com/alerts for more info"
                   }
                 ]
               },
               ^footer_instance
             ] =
               ElevatorClosures.elevator_status_instances(
                 struct(Screen, app_id: :elevator_v2, app_params: config),
                 header_instance,
                 footer_instance
               )
    end

    test "Returns CurrentElevatorClosed if configured elevator is closed", %{
      config: config,
      header_instance: header_instance,
      footer_instance: footer_instance
    } do
      expect(@alert, :fetch_elevator_alerts_with_facilities, fn ->
        alerts = [
          build_alert(
            informed_entities: [%{stop: "place-test", facility: %{name: "Test", id: "111"}}]
          )
        ]

        {:ok, alerts}
      end)

      closed_header_instance = %{header_instance | variant: :closed}
      closed_footer_instance = %{footer_instance | variant: :closed}

      assert [
               ^closed_header_instance,
               %CurrentElevatorClosed{app_params: ^config},
               ^closed_footer_instance
             ] =
               ElevatorClosures.elevator_status_instances(
                 struct(Screen, app_id: :elevator_v2, app_params: config),
                 header_instance,
                 footer_instance
               )
    end

    test "Return empty routes on API error", %{
      config: config,
      header_instance: header_instance,
      footer_instance: footer_instance
    } do
      expect(@stop, :fetch_parent_station_name_map, fn ->
        {:ok, %{"place-test" => "Place Test"}}
      end)

      expect(@route, :fetch, fn %{stop_id: "place-test"} ->
        :error
      end)

      expect(@alert, :fetch_elevator_alerts_with_facilities, fn ->
        alerts = [
          build_alert(
            informed_entities: [
              %{stop: "place-test", facility: %{name: "Test", id: "facility-test"}}
            ]
          )
        ]

        {:ok, alerts}
      end)

      assert [
               ^header_instance,
               %ElevatorClosuresList{
                 app_params: ^config,
                 stations_with_closures: [
                   %ElevatorClosuresList.Station{
                     id: "place-test",
                     name: "Place Test",
                     closures: [%Closure{id: "facility-test", name: "Test"}]
                   }
                 ],
                 station_id: "place-test"
               },
               ^footer_instance
             ] =
               ElevatorClosures.elevator_status_instances(
                 struct(Screen, app_id: :elevator_v2, app_params: config),
                 header_instance,
                 footer_instance
               )
    end
  end
end
