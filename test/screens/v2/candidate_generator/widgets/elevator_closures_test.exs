defmodule Screens.V2.CandidateGenerator.Widgets.ElevatorClosuresTest do
  use ExUnit.Case, async: true
  alias Screens.Alerts.Alert
  alias Screens.Elevator
  alias Screens.Routes.Route
  alias Screens.Stops.Stop
  alias Screens.V2.CandidateGenerator.Widgets.ElevatorClosures
  alias Screens.V2.WidgetInstance.ElevatorStatus, as: ElevatorStatusWidget
  alias ScreensConfig.Screen
  alias ScreensConfig.V2.{ElevatorStatus, PreFare}

  import Mox
  import Screens.Inject

  @elevator injected(Elevator)
  @route injected(Route)
  @stop injected(Stop)

  setup do
    stub(@elevator, :get, fn id -> build_elevator(id) end)

    stub(@route, :fetch, fn _params -> {:ok, [%Route{id: "Red", type: :subway}]} end)

    stub(@stop, :fetch_parent_station_name_map, fn ->
      {:ok, %{"station_1" => "Station One"}}
    end)

    config = %Screen{
      app_params: %PreFare{
        header: nil,
        reconstructed_alert_widget: nil,
        elevator_status: %ElevatorStatus{
          parent_station_id: "station_1",
          platform_stop_ids: ["1001", "1002"]
        },
        full_line_map: nil,
        content_summary: nil
      },
      vendor: nil,
      device_id: nil,
      name: nil,
      app_id: nil
    }

    now = ~U[2025-03-07 12:00:00Z]

    {:ok, config: config, now: now}
  end

  #### HELPER FUNCTIONS
  defp build_elevator(id, fields \\ []) do
    struct!(
      %Elevator{
        id: id,
        alternate_ids: [],
        entering_redundancy: :none,
        exiting_redundancy: :none
      },
      fields
    )
  end

  defp build_alert(fields) do
    struct!(%Alert{active_period: [{DateTime.utc_now(), nil}], effect: :elevator_closure}, fields)
  end

  test "returns ElevatorStatusWidget with valid alerts", %{config: config, now: now} do
    location_context_mock = fn _screen_type, _station_id, _now ->
      {:ok, :mocked_location_context}
    end

    alerts_mock = fn ->
      {:ok,
       [
         build_alert(
           id: "alert_1",
           informed_entities: [%{facility: %{id: "elev_1", name: "Test"}, stop: "place-test"}]
         )
       ]}
    end

    result =
      ElevatorClosures.elevator_status_instances(config, now, location_context_mock, alerts_mock)

    assert [
             %ElevatorStatusWidget{
               alerts: [%Alert{id: "alert_1"}],
               station_id_to_name: %{"station_1" => "Station One"}
             }
           ] = result
  end

  test "returns empty list when there are no alerts", %{config: config, now: now} do
    location_context_mock = fn _screen_type, _station_id, _now ->
      {:ok, :mocked_location_context}
    end

    alerts_mock = fn -> {:ok, []} end

    result =
      ElevatorClosures.elevator_status_instances(config, now, location_context_mock, alerts_mock)

    assert [%ElevatorStatusWidget{alerts: []}] = result
  end

  test "filters out closure with a nearby redundancy", %{config: config, now: now} do
    location_context_mock = fn _screen_type, _station_id, _now ->
      {:ok, :mocked_location_context}
    end

    alerts_mock = fn ->
      {:ok,
       [
         build_alert(
           id: "alert_1",
           informed_entities: [%{facility: %{id: "elev_1"}, stop: "place-1"}]
         ),
         build_alert(
           id: "alert_2",
           informed_entities: [%{facility: %{id: "elev_2"}, stop: "place-2"}]
         )
       ]}
    end

    stub(@elevator, :get, fn
      "elev_1" -> build_elevator("elev_1", exiting_redundancy: :none)
      "elev_2" -> build_elevator("elev_2", exiting_redundancy: :nearby)
    end)

    result =
      ElevatorClosures.elevator_status_instances(config, now, location_context_mock, alerts_mock)

    assert [%ElevatorStatusWidget{alerts: [%Alert{id: "alert_1"}]}] = result
  end
end
