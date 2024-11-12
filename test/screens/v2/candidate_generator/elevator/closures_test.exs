defmodule Screens.V2.CandidateGenerator.Elevator.ClosuresTest do
  use ExUnit.Case, async: true

  import Mox
  setup :verify_on_exit!

  alias Screens.Alerts.{Alert, MockAlert}
  alias Screens.Facilities.MockFacility
  alias Screens.Routes.{MockRoute, Route}
  alias Screens.Stops.{MockStop, Stop}
  alias Screens.V2.CandidateGenerator.Elevator.Closures, as: ElevatorClosures
  alias ScreensConfig.Screen
  alias ScreensConfig.V2.Elevator

  describe "elevator_status_instances/1" do
    test "Only returns alerts with effect of :elevator_closure" do
      expect(MockFacility, :fetch_stop_for_facility, fn "111" ->
        {:ok, %Stop{id: "place-test"}}
      end)

      expect(MockStop, :fetch_parent_station_name_map, fn ->
        {:ok, %{"place-test" => "Place Test"}}
      end)

      expect(MockRoute, :fetch, fn %{stop_id: "place-test"} ->
        {:ok, [%Route{id: "Red", type: :subway}]}
      end)

      expect(MockAlert, :fetch_elevator_alerts_with_facilities, fn ->
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
          id: "111",
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
          struct(Screen, app_id: :elevator_v2, app_params: %Elevator{elevator_id: "111"})
        )
    end

    test "Groups outside closures by station" do
      expect(MockFacility, :fetch_stop_for_facility, fn "111" ->
        {:ok, %Stop{id: "place-test"}}
      end)

      expect(MockStop, :fetch_parent_station_name_map, fn ->
        {:ok, %{"place-haecl" => "Haymarket"}}
      end)

      expect(MockRoute, :fetch, 2, fn
        %{stop_id: "place-haecl"} ->
          {:ok, [%Route{id: "Orange", type: :subway}]}

        %{stop_id: "place-test"} ->
          {:ok, [%Route{id: "Red", type: :subway}]}
      end)

      expect(MockAlert, :fetch_elevator_alerts_with_facilities, fn ->
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
          id: "111",
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
          struct(Screen, app_id: :elevator_v2, app_params: %Elevator{elevator_id: "111"})
        )
    end

    test "Filters alerts with no facilities or more than one facility" do
      expect(MockFacility, :fetch_stop_for_facility, fn "111" ->
        {:ok, %Stop{id: "place-test"}}
      end)

      expect(MockStop, :fetch_parent_station_name_map, fn ->
        {:ok, %{"place-haecl" => "Haymarket"}}
      end)

      expect(MockRoute, :fetch, fn _ -> {:ok, [%Route{id: "Red", type: :subway}]} end)

      expect(MockAlert, :fetch_elevator_alerts_with_facilities, fn ->
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
          id: "111",
          in_station_closures: [],
          other_stations_with_closures: []
        }
      ] =
        ElevatorClosures.elevator_status_instances(
          struct(Screen, app_id: :elevator_v2, app_params: %Elevator{elevator_id: "111"})
        )
    end

    test "Return empty routes on API error" do
      expect(MockFacility, :fetch_stop_for_facility, fn "111" ->
        {:ok, %Stop{id: "place-test"}}
      end)

      expect(MockStop, :fetch_parent_station_name_map, fn ->
        {:ok, %{"place-test" => "Place Test"}}
      end)

      expect(MockRoute, :fetch, fn %{stop_id: "place-test"} ->
        :error
      end)

      expect(MockAlert, :fetch_elevator_alerts_with_facilities, fn ->
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
          id: "111",
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
          struct(Screen, app_id: :elevator_v2, app_params: %Elevator{elevator_id: "111"})
        )
    end
  end
end
