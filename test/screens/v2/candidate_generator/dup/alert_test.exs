defmodule Screens.V2.CandidateGenerator.Dup.AlertTest do
  # DUP Special Case alerts are handled in dup_special_case_alert_test.exs
  use ExUnit.Case, async: true

  alias Screens.Alerts.Alert
  alias Screens.LocationContext
  alias Screens.V2.CandidateGenerator.Dup.Alerts
  alias ScreensConfig.Alerts, as: AlertsConfig
  alias ScreensConfig.Screen
  alias ScreensConfig.Screen.Dup

  @stop_id "place-bbsta"
  @base_alert %Alert{
    active_period: [{~U[2025-09-18 02:30:00Z], nil}],
    cause: :accident,
    created_at: ~U[2025-09-18 02:30:00Z],
    description: nil,
    effect: :delay,
    header: "Orange Line experiencing delays up to 20 minutes.",
    id: "999",
    informed_entities: [
      %{
        stop: "place-bbsta",
        route: "Orange",
        direction_id: nil,
        route_type: nil,
        activities: ~w[board exit ride]a,
        facility: nil
      }
    ],
    lifecycle: "ONGOING",
    severity: 5,
    timeframe: nil,
    updated_at: ~U[2025-09-18 02:30:00Z],
    url: nil
  }

  @config %Screen{
    app_id: "Test",
    device_id: "Test Device",
    name: "Test Name",
    vendor: "Test Vendor",
    app_params: %Dup{
      primary_departures: [],
      secondary_departures: [],
      alerts: %AlertsConfig{stop_id: @stop_id},
      header: %{stop_name: "Back Bay"}
    }
  }

  @now ~U[2025-09-18 02:30:00Z]

  defp fetch_stop_name_fn(_) do
    "Back Bay"
  end

  defp fetch_alerts_fn(options \\ %{}) do
    {:ok, [Map.merge(@base_alert, options)]}
  end

  defp fetch_location_context_fn(stop_id \\ "place-bbsta") do
    tagged_stop_sequences = %{
      "Orange" => [["place-tumnl", "place-bbsta", "place-masta"]]
    }

    stop_sequences = LocationContext.untag_stop_sequences(tagged_stop_sequences)

    routes_at_stop = [
      %{
        route_id: "Orange",
        active?: true,
        direction_destinations: nil,
        long_name: nil,
        short_name: nil,
        type: :subway
      }
    ]

    {:ok,
     %LocationContext{
       home_stop: stop_id,
       tagged_stop_sequences: tagged_stop_sequences,
       upstream_stops: LocationContext.upstream_stop_id_set([stop_id], stop_sequences),
       downstream_stops: LocationContext.downstream_stop_id_set([stop_id], stop_sequences),
       routes: routes_at_stop,
       alert_route_types: LocationContext.route_type_filter(Dup, [stop_id])
     }}
  end

  describe "alert_instances/5" do
    test "returns alert instances" do
      actual_widgets =
        Alerts.alert_instances(
          @config,
          @now,
          &fetch_stop_name_fn/1,
          fn _ -> fetch_alerts_fn() end,
          fn _, _, _ -> fetch_location_context_fn() end
        )

      assert [
               %{
                 alert: %{
                   id: "999",
                   cause: :accident,
                   effect: :delay,
                   severity: 5,
                   header: "Orange Line experiencing delays up to 20 minutes.",
                   informed_entities: [
                     %{
                       stop: "place-bbsta",
                       route: "Orange",
                       direction_id: nil,
                       route_type: nil,
                       activities: [:board, :exit, :ride],
                       facility: nil
                     }
                   ],
                   active_period: [{@now, nil}],
                   lifecycle: "ONGOING",
                   timeframe: nil,
                   created_at: @now,
                   updated_at: @now,
                   url: nil,
                   description: nil
                 },
                 rotation_index: :zero,
                 stop_name: "Back Bay"
               },
               %{
                 alert: %{
                   id: "999",
                   cause: :accident,
                   effect: :delay,
                   severity: 5,
                   header: "Orange Line experiencing delays up to 20 minutes.",
                   informed_entities: [
                     %{
                       stop: "place-bbsta",
                       route: "Orange",
                       direction_id: nil,
                       route_type: nil,
                       activities: [:board, :exit, :ride],
                       facility: nil
                     }
                   ],
                   active_period: [{@now, nil}],
                   lifecycle: "ONGOING",
                   timeframe: nil,
                   created_at: @now,
                   updated_at: @now,
                   url: nil,
                   description: nil
                 },
                 rotation_index: :one,
                 stop_name: "Back Bay"
               },
               %{
                 alert: %{
                   id: "999",
                   cause: :accident,
                   effect: :delay,
                   severity: 5,
                   header: "Orange Line experiencing delays up to 20 minutes.",
                   informed_entities: [
                     %{
                       stop: "place-bbsta",
                       route: "Orange",
                       direction_id: nil,
                       route_type: nil,
                       activities: [:board, :exit, :ride],
                       facility: nil
                     }
                   ],
                   active_period: [{@now, nil}],
                   lifecycle: "ONGOING",
                   timeframe: nil,
                   created_at: @now,
                   updated_at: @now,
                   url: nil,
                   description: nil
                 },
                 rotation_index: :two,
                 stop_name: "Back Bay"
               }
             ] = actual_widgets
    end
  end

  test "does not return alert for informational single tracking" do
    actual_widgets =
      Alerts.alert_instances(
        @config,
        @now,
        &fetch_stop_name_fn/1,
        fn _ ->
          fetch_alerts_fn(%{
            severity: 1,
            cause: :single_tracking
          })
        end,
        fn _, _, _ -> fetch_location_context_fn() end
      )

    assert [] == actual_widgets
  end

  test "does not return DUP alert for alerts that are not happening now" do
    actual_widgets =
      Alerts.alert_instances(
        @config,
        ~U[2025-09-16 02:30:00Z],
        &fetch_stop_name_fn/1,
        fn _ -> fetch_alerts_fn() end,
        fn _, _, _ -> fetch_location_context_fn() end
      )

    assert [] == actual_widgets
  end

  test "does not return DUP alert for alerts not happening here" do
    actual_widgets =
      Alerts.alert_instances(
        @config,
        @now,
        &fetch_stop_name_fn/1,
        fn _ -> fetch_alerts_fn() end,
        fn _, _, _ -> fetch_location_context_fn("place-masta") end
      )

    assert [] == actual_widgets
  end

  test "does not return alert for alerts that are not severe enough" do
    actual_widgets =
      Alerts.alert_instances(
        @config,
        @now,
        &fetch_stop_name_fn/1,
        fn _ ->
          fetch_alerts_fn(%{
            severity: 4
          })
        end,
        fn _, _, _ -> fetch_location_context_fn() end
      )

    assert [] == actual_widgets
  end
end
