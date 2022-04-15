defmodule Screens.V2.CandidateGenerator.Widgets.ReconstructedAlertTest do
  use ExUnit.Case, async: true

  import Screens.V2.CandidateGenerator.Widgets.ReconstructedAlert

  alias Screens.Alerts.Alert
  alias Screens.Config.Screen
  alias Screens.Config.V2.Header.CurrentStopId
  alias Screens.Config.V2.{PreFare, Solari}
  alias Screens.V2.WidgetInstance.ReconstructedAlert, as: ReconstructedAlertWidget

  defp ie(opts) do
    %{stop: opts[:stop], route: opts[:route], route_type: opts[:route_type]}
  end

  describe "reconstructed_alert_instances/5" do
    setup do
      config =
        struct(Screen, %{
          app_id: :pre_fare_v2,
          app_params:
            struct(PreFare, %{reconstructed_alert_widget: %CurrentStopId{stop_id: "place-hsmnl"}})
        })

      bad_config = struct(Screen, %{app_params: struct(Solari)})

      routes_at_stop = [
        %{
          route_id: "Red",
          active?: true,
          direction_destinations: nil,
          long_name: nil,
          short_name: nil,
          type: :subway
        },
        %{
          route_id: "Green-B",
          active?: false,
          direction_destinations: nil,
          long_name: nil,
          short_name: nil,
          type: :light_rail
        },
        %{
          route_id: "Green-C",
          active?: true,
          direction_destinations: nil,
          long_name: nil,
          short_name: nil,
          type: :light_rail
        },
        %{
          route_id: "Green-D",
          active?: true,
          direction_destinations: nil,
          long_name: nil,
          short_name: nil,
          type: :light_rail
        },
        %{
          route_id: "Green-E",
          active?: true,
          direction_destinations: nil,
          long_name: nil,
          short_name: nil,
          type: :light_rail
        }
      ]

      alerts = [
        %Alert{id: "1", effect: :station_closure, informed_entities: [ie(stop: "place-hsmnl")]},
        %Alert{id: "2", effect: :station_closure, informed_entities: [ie(stop: "place-bckhl")]},
        %Alert{id: "3", effect: :delay, informed_entities: [ie(stop: "place-hsmnl")]},
        %Alert{id: "4", effect: :station_closure, informed_entities: []},
        %Alert{id: "5", effect: :stop_closure, informed_entities: [ie(stop: "place-rvrwy")]}
      ]

      station_sequences = [
        ["place-hsmnl", "place-bckhl", "place-rvrwy", "place-mispk"]
      ]

      %{
        config: config,
        bad_config: bad_config,
        routes_at_stop: routes_at_stop,
        station_sequences: station_sequences,
        now: ~U[2021-01-01T00:00:00Z],
        informed_station_string: "Alewife",
        fetch_routes_by_stop_fn: fn _, _, _ -> {:ok, routes_at_stop} end,
        fetch_parent_station_sequences_through_stop_fn: fn _, _ ->
          {:ok, station_sequences}
        end,
        fetch_alerts_fn: fn _ -> {:ok, alerts} end,
        fetch_stop_name_fn: fn _ -> "Alewife" end,
        x_fetch_routes_by_stop_fn: fn _, _, _ -> :error end,
        x_fetch_parent_station_sequences_through_stop_fn: fn _, _ -> :error end,
        x_fetch_alerts_fn: fn _ -> :error end,
        x_fetch_stop_name_fn: fn _ -> :error end
      }
    end

    test "returns a list of alert widgets if all queries succeed", context do
      %{
        config: config,
        routes_at_stop: routes_at_stop,
        station_sequences: station_sequences,
        now: now,
        informed_station_string: informed_station_string,
        fetch_routes_by_stop_fn: fetch_routes_by_stop_fn,
        fetch_parent_station_sequences_through_stop_fn:
          fetch_parent_station_sequences_through_stop_fn,
        fetch_alerts_fn: fetch_alerts_fn,
        fetch_stop_name_fn: fetch_stop_name_fn
      } = context

      expected_common_data = %{
        screen: config,
        routes_at_stop: routes_at_stop,
        stop_sequences: station_sequences,
        now: now,
        informed_station_string: informed_station_string
      }

      expected_widgets = [
        struct(
          %ReconstructedAlertWidget{
            alert: %Alert{
              id: "1",
              effect: :station_closure,
              informed_entities: [ie(stop: "place-hsmnl")]
            }
          },
          expected_common_data
        ),
        struct(
          %ReconstructedAlertWidget{
            alert: %Alert{
              id: "2",
              effect: :station_closure,
              informed_entities: [ie(stop: "place-bckhl")]
            }
          },
          expected_common_data
        ),
        struct(
          %ReconstructedAlertWidget{
            alert: %Alert{id: "3", effect: :delay, informed_entities: [ie(stop: "place-hsmnl")]}
          },
          expected_common_data
        )
      ]

      assert expected_widgets ==
               reconstructed_alert_instances(
                 config,
                 now,
                 fetch_routes_by_stop_fn,
                 fetch_parent_station_sequences_through_stop_fn,
                 fetch_alerts_fn,
                 fetch_stop_name_fn
               )
    end

    test "fails when passed config for an unsupported screen type", context do
      %{
        bad_config: bad_config,
        now: now,
        fetch_routes_by_stop_fn: fetch_routes_by_stop_fn,
        fetch_parent_station_sequences_through_stop_fn:
          fetch_parent_station_sequences_through_stop_fn,
        fetch_alerts_fn: fetch_alerts_fn,
        fetch_stop_name_fn: fetch_stop_name_fn
      } = context

      assert_raise FunctionClauseError, fn ->
        reconstructed_alert_instances(
          bad_config,
          now,
          fetch_routes_by_stop_fn,
          fetch_parent_station_sequences_through_stop_fn,
          fetch_alerts_fn,
          fetch_stop_name_fn
        )
      end
    end

    test "returns empty list if any query fails", context do
      %{
        config: config,
        now: now,
        fetch_routes_by_stop_fn: fetch_routes_by_stop_fn,
        fetch_parent_station_sequences_through_stop_fn:
          fetch_parent_station_sequences_through_stop_fn,
        fetch_alerts_fn: fetch_alerts_fn,
        fetch_stop_name_fn: fetch_stop_name_fn,
        x_fetch_routes_by_stop_fn: x_fetch_routes_by_stop_fn,
        x_fetch_parent_station_sequences_through_stop_fn:
          x_fetch_parent_station_sequences_through_stop_fn,
        x_fetch_alerts_fn: x_fetch_alerts_fn
      } = context

      assert [] ==
               reconstructed_alert_instances(
                 config,
                 now,
                 x_fetch_routes_by_stop_fn,
                 fetch_parent_station_sequences_through_stop_fn,
                 fetch_alerts_fn,
                 fetch_stop_name_fn
               )

      assert [] ==
               reconstructed_alert_instances(
                 config,
                 now,
                 fetch_routes_by_stop_fn,
                 x_fetch_parent_station_sequences_through_stop_fn,
                 fetch_alerts_fn,
                 fetch_stop_name_fn
               )

      assert [] ==
               reconstructed_alert_instances(
                 config,
                 now,
                 fetch_routes_by_stop_fn,
                 fetch_parent_station_sequences_through_stop_fn,
                 x_fetch_alerts_fn,
                 fetch_stop_name_fn
               )
    end

    test "fails gracefully if get_station query fails", context do
      %{
        config: config,
        routes_at_stop: routes_at_stop,
        station_sequences: station_sequences,
        now: now,
        fetch_routes_by_stop_fn: fetch_routes_by_stop_fn,
        fetch_parent_station_sequences_through_stop_fn:
          fetch_parent_station_sequences_through_stop_fn,
        fetch_alerts_fn: fetch_alerts_fn,
        x_fetch_stop_name_fn: x_fetch_stop_name_fn
      } = context

      expected_common_data = %{
        screen: config,
        routes_at_stop: routes_at_stop,
        stop_sequences: station_sequences,
        now: now,
        informed_station_string: ""
      }

      expected_widgets = [
        struct(
          %ReconstructedAlertWidget{
            alert: %Alert{
              id: "1",
              effect: :station_closure,
              informed_entities: [ie(stop: "place-hsmnl")]
            }
          },
          expected_common_data
        ),
        struct(
          %ReconstructedAlertWidget{
            alert: %Alert{
              id: "2",
              effect: :station_closure,
              informed_entities: [ie(stop: "place-bckhl")]
            }
          },
          expected_common_data
        ),
        struct(
          %ReconstructedAlertWidget{
            alert: %Alert{id: "3", effect: :delay, informed_entities: [ie(stop: "place-hsmnl")]}
          },
          expected_common_data
        )
      ]

      assert expected_widgets ==
               reconstructed_alert_instances(
                 config,
                 now,
                 fetch_routes_by_stop_fn,
                 fetch_parent_station_sequences_through_stop_fn,
                 fetch_alerts_fn,
                 x_fetch_stop_name_fn
               )
    end
  end
end
