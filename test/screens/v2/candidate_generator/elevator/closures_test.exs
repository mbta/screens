defmodule Screens.V2.CandidateGenerator.Elevator.ClosuresTest do
  use ExUnit.Case, async: true

  import Mox
  setup :verify_on_exit!

  alias Screens.Alerts.{Alert, MockAlert}
  alias Screens.Facilities.MockFacility
  alias Screens.LocationContext
  alias Screens.Routes.{MockRoute, Route}
  alias Screens.Stops.{MockStop, Stop}
  alias Screens.V2.CandidateGenerator.Elevator.Closures, as: ElevatorClosures
  alias ScreensConfig.Screen
  alias ScreensConfig.V2.Elevator

  describe "elevator_status_instances/5" do
    test "Only returns alerts with effect of :elevator_closure" do
      now = ~U[2024-10-01T05:00:00Z]

      expect(MockFacility, :fetch_stop_for_facility, fn "111" ->
        {:ok, %Stop{id: "place-test"}}
      end)

      expect(MockStop, :fetch_location_context, fn Elevator, "place-test", ^now ->
        {:ok, %LocationContext{home_stop: "place-test"}}
      end)

      expect(MockStop, :fetch_parent_station_name_map, fn ->
        {:ok, [%{"place-test" => "Place Test"}]}
      end)

      expect(MockRoute, :fetch, fn %{stop_id: "place-test"} ->
        {:ok, [%Route{id: "Red"}]}
      end)

      expect(MockAlert, :fetch_elevator_alerts_with_facilities, fn ->
        alerts = [
          struct(Alert, effect: :elevator_closure, informed_entities: [%{stop: "place-test"}]),
          struct(Alert, effect: :detour, informed_entities: [%{stop: "place-test"}])
        ]

        {:ok, alerts}
      end)

      [
        %Screens.V2.WidgetInstance.ElevatorClosures{
          screen: %Screen{
            app_id: :elevator_v2,
            app_params: %Elevator{elevator_id: "111", evergreen_content: []}
          },
          alerts: [
            %Alert{
              effect: :elevator_closure,
              informed_entities: [%{stop: "place-test"}]
            }
          ],
          location_context: %LocationContext{
            home_stop: "place-test"
          },
          now: ~U[2024-10-01 05:00:00Z],
          station_id_to_name: [%{"place-test" => "Place Test"}],
          station_id_to_routes: %{"place-test" => ["Red"]}
        }
      ] =
        ElevatorClosures.elevator_status_instances(
          struct(Screen, app_id: :elevator_v2, app_params: %Elevator{elevator_id: "111"}),
          now
        )
    end

    test "Return empty routes on API error" do
      now = ~U[2024-10-01T05:00:00Z]

      expect(MockFacility, :fetch_stop_for_facility, fn "111" ->
        {:ok, %Stop{id: "place-test"}}
      end)

      expect(MockStop, :fetch_location_context, fn Elevator, "place-test", ^now ->
        {:ok, %LocationContext{home_stop: "place-test"}}
      end)

      expect(MockStop, :fetch_parent_station_name_map, fn ->
        {:ok, [%{"place-test" => "Place Test"}]}
      end)

      expect(MockRoute, :fetch, fn %{stop_id: "place-test"} ->
        :error
      end)

      expect(MockAlert, :fetch_elevator_alerts_with_facilities, fn ->
        alerts = [
          struct(Alert, effect: :elevator_closure, informed_entities: [%{stop: "place-test"}])
        ]

        {:ok, alerts}
      end)

      [
        %Screens.V2.WidgetInstance.ElevatorClosures{
          screen: %Screen{
            app_id: :elevator_v2,
            app_params: %Elevator{elevator_id: "111", evergreen_content: []}
          },
          alerts: [
            %Alert{
              effect: :elevator_closure,
              informed_entities: [%{stop: "place-test"}]
            }
          ],
          location_context: %LocationContext{
            home_stop: "place-test"
          },
          now: ~U[2024-10-01 05:00:00Z],
          station_id_to_name: [%{"place-test" => "Place Test"}],
          station_id_to_routes: %{"place-test" => []}
        }
      ] =
        ElevatorClosures.elevator_status_instances(
          struct(Screen, app_id: :elevator_v2, app_params: %Elevator{elevator_id: "111"}),
          now
        )
    end
  end
end
