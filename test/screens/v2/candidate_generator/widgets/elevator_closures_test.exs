defmodule Screens.V2.CandidateGenerator.Widgets.ElevatorClosuresTest do
  use ExUnit.Case, async: true

  alias Screens.Alerts.Alert
  alias Screens.Elevator
  alias Screens.Facilities.Facility
  alias Screens.Routes.Route
  alias Screens.Stops.Stop
  alias Screens.V2.CandidateGenerator.Widgets.ElevatorClosures
  alias Screens.V2.WidgetInstance.ElevatorStatus, as: ElevatorStatusWidget
  alias ScreensConfig.{ElevatorStatus, Screen}
  alias ScreensConfig.Screen.PreFare

  import Mox
  import Screens.Inject

  @elevator injected(Elevator)
  @route injected(Route)
  @stop injected(Stop)

  @alert_opts [activities: [:using_wheelchair]]

  setup :verify_on_exit!

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
          parent_station_id: "place-test-parent-station-id",
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
    struct!(%Elevator{id: id, alternate_ids: [], exiting_summary: "", redundancy: :other}, fields)
  end

  defp build_facility(id, fields \\ []) do
    struct!(
      %Facility{id: id, long_name: "long", short_name: "short", type: :elevator, stop: :unloaded},
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

    alerts_mock = fn @alert_opts ->
      {:ok,
       [
         build_alert(
           id: "alert_1",
           informed_entities: [%{facility: build_facility("elev_1"), stop: "place-test"}]
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

    alerts_mock = fn @alert_opts -> {:ok, []} end

    result =
      ElevatorClosures.elevator_status_instances(config, now, location_context_mock, alerts_mock)

    assert [%ElevatorStatusWidget{alerts: []}] = result
  end

  test "filters out closure with a nearby redundancy", %{config: config, now: now} do
    location_context_mock = fn _screen_type, _station_id, _now ->
      {:ok, :mocked_location_context}
    end

    alerts_mock = fn @alert_opts ->
      {:ok,
       [
         build_alert(
           id: "alert_1",
           informed_entities: [%{facility: build_facility("elev_1"), stop: "place-1"}]
         ),
         build_alert(
           id: "alert_2",
           informed_entities: [%{facility: build_facility("elev_2"), stop: "place-2"}]
         )
       ]}
    end

    stub(@elevator, :get, fn
      "elev_1" -> build_elevator("elev_1", redundancy: :none)
      "elev_2" -> build_elevator("elev_2", redundancy: :nearby)
    end)

    result =
      ElevatorClosures.elevator_status_instances(config, now, location_context_mock, alerts_mock)

    assert [%ElevatorStatusWidget{alerts: [%Alert{id: "alert_1"}]}] = result
  end

  test "filters out closure with an alternate elevator open", %{config: config, now: now} do
    location_context_mock = fn _screen_type, _station_id, _now ->
      {:ok, :mocked_location_context}
    end

    alerts_mock = fn @alert_opts ->
      {:ok,
       [
         build_alert(
           id: "alert_1",
           informed_entities: [%{facility: build_facility("elev_1"), stop: "place-1"}]
         ),
         build_alert(
           id: "alert_2",
           informed_entities: [%{facility: build_facility("elev_2"), stop: "place-2"}]
         )
       ]}
    end

    stub(@elevator, :get, fn
      "elev_1" -> build_elevator("elev_1", redundancy: :nearby, alternate_ids: ["elev_3"])
      "elev_2" -> build_elevator("elev_2", redundancy: :nearby)
      "elev_3" -> build_elevator("elev_3", redundancy: :nearby)
    end)

    result =
      ElevatorClosures.elevator_status_instances(config, now, location_context_mock, alerts_mock)

    assert [%ElevatorStatusWidget{alerts: []}] = result
  end

  test "does not filter out closure with an alternate elevator closed", %{
    config: config,
    now: now
  } do
    location_context_mock = fn _screen_type, _station_id, _now ->
      {:ok, :mocked_location_context}
    end

    alerts_mock = fn @alert_opts ->
      {:ok,
       [
         build_alert(
           id: "alert_1",
           informed_entities: [%{facility: build_facility("elev_1"), stop: "place-1"}]
         ),
         build_alert(
           id: "alert_2",
           informed_entities: [%{facility: build_facility("elev_2"), stop: "place-2"}]
         ),
         build_alert(
           id: "alert_3",
           informed_entities: [%{facility: build_facility("elev_3"), stop: "place-1"}]
         )
       ]}
    end

    stub(@elevator, :get, fn
      "elev_1" ->
        build_elevator("elev_1", redundancy: :nearby, alternate_ids: ["elev_3"])

      "elev_2" ->
        build_elevator("elev_2", redundancy: :nearby)

      "elev_3" ->
        build_elevator("elev_3", redundancy: :nearby)
    end)

    result =
      ElevatorClosures.elevator_status_instances(config, now, location_context_mock, alerts_mock)

    assert [%ElevatorStatusWidget{alerts: [%Alert{id: "alert_1"}]}] = result
  end

  test "does not filter closure in the same station, even if redundancy exists", %{
    config: config,
    now: now
  } do
    location_context_mock = fn _screen_type, _station_id, _now ->
      {:ok, :mocked_location_context}
    end

    alerts_mock = fn @alert_opts ->
      {:ok,
       [
         build_alert(
           id: "alert_1",
           informed_entities: [
             %{facility: build_facility("elev_1"), stop: "place-test-parent-station-id"}
           ]
         )
       ]}
    end

    stub(@elevator, :get, fn
      "elev_1" -> build_elevator("elev_1", redundancy: :nearby, alternate_ids: ["elev_2"])
    end)

    result =
      ElevatorClosures.elevator_status_instances(config, now, location_context_mock, alerts_mock)

    assert [%ElevatorStatusWidget{alerts: [%Alert{id: "alert_1"}]}] = result
  end
end
