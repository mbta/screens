defmodule Screens.V2.CandidateGenerator.Elevator.ClosuresTest do
  use ExUnit.Case, async: true

  alias Screens.Alerts.Alert
  alias Screens.Routes.Route
  alias Screens.Stops.Stop
  alias Screens.V2.CandidateGenerator.Elevator.Closures, as: ElevatorClosures
  alias ScreensConfig.Screen
  alias ScreensConfig.V2.Elevator

  import Screens.Inject
  import Mox
  setup :verify_on_exit!

  @alert injected(Alert)
  @facility injected(Screens.Facilities.Facility)
  @route injected(Route)
  @stop injected(Stop)

  describe "elevator_status_instances/1" do
    setup do
      %{
        config: %Elevator{
          elevator_id: "111",
          accessible_path_direction_arrow: :n,
          alternate_direction_text: "Test"
        }
      }
    end

    test "Only returns alerts with effect of :elevator_closure", %{config: config} do
      expect(@facility, :fetch_stop_for_facility, fn "111" -> {:ok, %Stop{id: "place-test"}} end)

      expect(@stop, :fetch_parent_station_name_map, fn ->
        {:ok, %{"place-test" => "Place Test"}}
      end)

      expect(@route, :fetch, fn %{stop_id: "place-test"} ->
        {:ok, [%Route{id: "Red", type: :subway}]}
      end)

      expect(@alert, :fetch_elevator_alerts_with_facilities, fn ->
        alerts = [
          struct(Alert,
            id: "1",
            effect: :elevator_closure,
            informed_entities: [
              %{stop: "place-test", facility: %{name: "Test", id: "facility-test"}}
            ]
          ),
          struct(Alert,
            effect: :detour,
            informed_entities: [
              %{stop: "place-test", facility: %{name: "Test 2", id: "facility-test2"}}
            ]
          )
        ]

        {:ok, alerts}
      end)

      [
        %Screens.V2.WidgetInstance.ElevatorClosures{
          elevator_config: ^config,
          in_station_closures: [
            %{
              id: "1",
              description: nil,
              elevator_name: "Test",
              elevator_id: "facility-test",
              header_text: nil
            }
          ],
          other_stations_with_closures: []
        }
      ] =
        ElevatorClosures.elevator_status_instances(
          struct(Screen, app_id: :elevator_v2, app_params: config)
        )
    end

    test "Groups outside closures by station", %{config: config} do
      expect(@facility, :fetch_stop_for_facility, fn "111" -> {:ok, %Stop{id: "place-test"}} end)

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
          struct(Alert,
            id: "1",
            effect: :elevator_closure,
            informed_entities: [
              %{stop: "place-haecl", facility: %{name: "Test 1", id: "facility-test-1"}}
            ]
          ),
          struct(Alert,
            id: "2",
            effect: :elevator_closure,
            informed_entities: [
              %{stop: "place-haecl", facility: %{name: "Test 2", id: "facility-test-2"}}
            ]
          )
        ]

        {:ok, alerts}
      end)

      [
        %Screens.V2.WidgetInstance.ElevatorClosures{
          elevator_config: ^config,
          in_station_closures: [],
          other_stations_with_closures: [
            %{
              id: "place-haecl",
              name: "Haymarket",
              route_icons: [%{type: :text, text: "OL", color: :orange}],
              closures: [
                %{
                  id: "1",
                  description: nil,
                  elevator_name: "Test 1",
                  elevator_id: "facility-test-1",
                  header_text: nil
                },
                %{
                  id: "2",
                  description: nil,
                  elevator_name: "Test 2",
                  elevator_id: "facility-test-2",
                  header_text: nil
                }
              ]
            }
          ]
        }
      ] =
        ElevatorClosures.elevator_status_instances(
          struct(Screen, app_id: :elevator_v2, app_params: config)
        )
    end

    test "Filters alerts with no facilities or more than one facility", %{config: config} do
      expect(@facility, :fetch_stop_for_facility, fn "111" -> {:ok, %Stop{id: "place-test"}} end)

      expect(@stop, :fetch_parent_station_name_map, fn ->
        {:ok, %{"place-haecl" => "Haymarket"}}
      end)

      expect(@route, :fetch, fn _ -> {:ok, [%Route{id: "Red", type: :subway}]} end)

      expect(@alert, :fetch_elevator_alerts_with_facilities, fn ->
        alerts = [
          struct(Alert,
            id: "1",
            effect: :elevator_closure,
            informed_entities: [
              %{stop: "place-haecl"}
            ]
          ),
          struct(Alert,
            id: "2",
            effect: :elevator_closure,
            informed_entities: [
              %{stop: "place-haecl", facility: %{name: "Test 2", id: "facility-test-2"}},
              %{stop: "place-haecl", facility: %{name: "Test 2", id: "facility-test-3"}}
            ]
          )
        ]

        {:ok, alerts}
      end)

      [
        %Screens.V2.WidgetInstance.ElevatorClosures{
          elevator_config: ^config,
          in_station_closures: [],
          other_stations_with_closures: []
        }
      ] =
        ElevatorClosures.elevator_status_instances(
          struct(Screen, app_id: :elevator_v2, app_params: config)
        )
    end

    test "Return empty routes on API error", %{config: config} do
      expect(@facility, :fetch_stop_for_facility, fn "111" -> {:ok, %Stop{id: "place-test"}} end)

      expect(@stop, :fetch_parent_station_name_map, fn ->
        {:ok, %{"place-test" => "Place Test"}}
      end)

      expect(@route, :fetch, fn %{stop_id: "place-test"} ->
        :error
      end)

      expect(@alert, :fetch_elevator_alerts_with_facilities, fn ->
        alerts = [
          struct(Alert,
            id: "1",
            effect: :elevator_closure,
            informed_entities: [
              %{stop: "place-test", facility: %{name: "Test", id: "facility-test"}}
            ]
          )
        ]

        {:ok, alerts}
      end)

      [
        %Screens.V2.WidgetInstance.ElevatorClosures{
          elevator_config: ^config,
          in_station_closures: [
            %{
              id: "1",
              description: nil,
              elevator_name: "Test",
              elevator_id: "facility-test",
              header_text: nil
            }
          ],
          other_stations_with_closures: []
        }
      ] =
        ElevatorClosures.elevator_status_instances(
          struct(Screen, app_id: :elevator_v2, app_params: config)
        )
    end
  end
end
