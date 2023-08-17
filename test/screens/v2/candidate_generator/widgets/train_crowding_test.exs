defmodule Screens.V2.CandidateGenerator.Widgets.TrainCrowdingTest do
  use ExUnit.Case, async: true

  import Screens.V2.CandidateGenerator.Widgets.TrainCrowding

  alias Screens.Config.Screen
  alias Screens.Config.V2.{TrainCrowding, Triptych}
  alias Screens.Predictions.Prediction
  alias Screens.Vehicles.Vehicle
  alias Screens.V2.WidgetInstance.TrainCrowding, as: CrowdingWidget

  setup :setup_base

  defp setup_base(_) do
    config = %Screen{
      app_params: %Triptych{
        train_crowding: %TrainCrowding{
          station_id: "place-masta",
          direction_id: 1,
          platform_position: 2.5,
          front_car_direction: "right",
          enabled: true
        },
        evergreen_content: []
      },
      vendor: :outfront,
      device_id: "TEST",
      name: "TEST",
      app_id: :triptych_v2
    }

    next_train_prediction =
      struct(Prediction, %{
        vehicle: struct(Vehicle, %{stop_id: "10001", current_status: :incoming_at})
      })

    location_context = %Screens.LocationContext{
      home_stop: "place-masta",
      stop_sequences: [
        [
          "place-ogmnl",
          "place-mlmnl",
          "place-welln",
          "place-astao",
          "place-sull",
          "place-ccmnl",
          "place-north",
          "place-haecl",
          "place-state",
          "place-dwnxg",
          "place-chncl",
          "place-tumnl",
          "place-bbsta",
          "place-masta",
          "place-rugg",
          "place-rcmnl",
          "place-jaksn",
          "place-sbmnl",
          "place-grnst",
          "place-forhl"
        ]
      ],
      upstream_stops:
        MapSet.new([
          "place-astao",
          "place-bbsta",
          "place-ccmnl",
          "place-chncl",
          "place-dwnxg",
          "place-haecl",
          "place-mlmnl",
          "place-north",
          "place-ogmnl",
          "place-state",
          "place-sull",
          "place-tumnl",
          "place-welln"
        ]),
      downstream_stops:
        MapSet.new([
          "place-forhl",
          "place-grnst",
          "place-jaksn",
          "place-rcmnl",
          "place-rugg",
          "place-sbmnl"
        ]),
      routes: [
        %{
          active?: true,
          direction_destinations: ["Forest Hills", "Oak Grove"],
          long_name: "Orange Line",
          route_id: "Orange",
          short_name: "",
          type: :subway
        }
      ],
      alert_route_types: [:light_rail, :subway]
    }

    alerts = [
      %Screens.Alerts.Alert{
        id: "141245",
        cause: :unknown,
        effect: :shuttle,
        severity: 7,
        header: "Shuttle buses replacing Orange Line service",
        informed_entities: [
          %{direction_id: nil, route: "Orange", route_type: 1, stop: "70012"},
          %{direction_id: nil, route: "Orange", route_type: 1, stop: "70013"},
          %{direction_id: nil, route: "Orange", route_type: 1, stop: "70014"},
          %{direction_id: nil, route: "Orange", route_type: 1, stop: "70015"},
          %{direction_id: nil, route: "Orange", route_type: 1, stop: "70016"},
          %{direction_id: nil, route: "Orange", route_type: 1, stop: "70017"},
          %{direction_id: nil, route: "Orange", route_type: 1, stop: "70018"},
          %{direction_id: nil, route: "Orange", route_type: 1, stop: "70019"},
          %{direction_id: nil, route: "Orange", route_type: 1, stop: "70020"},
          %{direction_id: nil, route: "Orange", route_type: 1, stop: "70021"},
          %{direction_id: nil, route: "Orange", route_type: 1, stop: "70022"},
          %{direction_id: nil, route: "Orange", route_type: 1, stop: "70023"},
          %{direction_id: nil, route: "Orange", route_type: 1, stop: "70024"},
          %{direction_id: nil, route: "Orange", route_type: 1, stop: "70025"},
          %{direction_id: nil, route: "Orange", route_type: 1, stop: "place-bbsta"},
          %{direction_id: nil, route: "Orange", route_type: 1, stop: "place-chncl"},
          %{direction_id: nil, route: "Orange", route_type: 1, stop: "place-dwnxg"},
          %{direction_id: nil, route: "Orange", route_type: 1, stop: "place-haecl"},
          %{direction_id: nil, route: "Orange", route_type: 1, stop: "place-masta"},
          %{direction_id: nil, route: "Orange", route_type: 1, stop: "place-state"},
          %{direction_id: nil, route: "Orange", route_type: 1, stop: "place-tumnl"}
        ],
        active_period: [{~U[2023-08-16 20:04:00Z], ~U[2023-08-16 22:04:06Z]}],
        lifecycle: "NEW",
        timeframe: nil,
        created_at: ~U[2023-08-16 20:04:02Z],
        updated_at: ~U[2023-08-16 20:04:02Z],
        url: nil,
        description:
          "Affected stops:\r\nHaymarket\r\nState\r\nDowntown Crossing\r\nChinatown\r\nTufts Medical Center\r\nBack Bay\r\nMassachusetts Avenue"
      }
    ]

    %{
      config: config,
      now: ~U[2023-08-16 21:04:00Z],
      next_train_prediction: next_train_prediction,
      fetch_predictions_fn: fn _ -> {:ok, [next_train_prediction]} end,
      fetch_location_context_fn: fn _, _, _ -> {:ok, location_context} end,
      fetch_parent_stop_id_fn: fn "10001" -> "place-masta" end,
      fetch_empty_alerts_fn: fn _ -> {:ok, []} end,
      fetch_alerts_fn: fn _ -> {:ok, alerts} end
    }
  end

  defp disable_widget(config) do
    %{
      config
      | app_params: %{
          config.app_params
          | train_crowding: %{config.app_params.train_crowding | enabled: false}
        }
    }
  end

  describe "crowding_widget_instances/3" do
    test "returns crowding widget if train is on the way to this station", context do
      assert crowding_widget_instances(
               context.config,
               context.now,
               context.fetch_predictions_fn,
               context.fetch_location_context_fn,
               context.fetch_parent_stop_id_fn,
               context.fetch_empty_alerts_fn
             ) == [
               %CrowdingWidget{
                 screen: context.config,
                 prediction: context.next_train_prediction,
                 now: context.now
               }
             ]
    end

    test "returns empty if train is not coming yet", context do
      alt_prediction =
        struct(Prediction, %{
          vehicle: struct(Vehicle, %{stop_id: "9999", current_status: :incoming_at})
        })

      assert crowding_widget_instances(
               context.config,
               context.now,
               fn _ -> {:ok, [alt_prediction]} end,
               context.fetch_location_context_fn,
               fn "9999" -> "place-bbsta" end,
               context.fetch_empty_alerts_fn
             ) == []
    end

    test "returns empty if train has already arrived at this station", context do
      alt_prediction =
        struct(Prediction, %{
          vehicle: struct(Vehicle, %{stop_id: "10001", current_status: :stopped_at})
        })

      assert crowding_widget_instances(
               context.config,
               context.now,
               fn _ -> {:ok, [alt_prediction]} end,
               context.fetch_location_context_fn,
               context.fetch_parent_stop_id_fn,
               context.fetch_empty_alerts_fn
             ) == []
    end

    test "returns empty if there is a shuttle / suspension that makes this station a temp terminal",
         context do
      assert crowding_widget_instances(
               context.config,
               context.now,
               context.fetch_predictions_fn,
               context.fetch_location_context_fn,
               context.fetch_parent_stop_id_fn,
               context.fetch_alerts_fn
             ) == []
    end

    test "returns empty if there are no predictions", context do
      assert crowding_widget_instances(
               context.config,
               context.now,
               fn _ -> {:ok, []} end,
               context.fetch_location_context_fn,
               context.fetch_parent_stop_id_fn,
               context.fetch_empty_alerts_fn
             ) == []
    end

    test "returns empty if any fetches fail", context do
      assert crowding_widget_instances(
               context.config,
               context.now,
               fn _ -> :error end,
               context.fetch_location_context_fn,
               context.fetch_parent_stop_id_fn,
               context.fetch_empty_alerts_fn
             ) == []

      assert crowding_widget_instances(
               context.config,
               context.now,
               context.fetch_predictions_fn,
               fn _, _, _ -> :error end,
               context.fetch_parent_stop_id_fn,
               context.fetch_empty_alerts_fn
             ) == []

      assert crowding_widget_instances(
               context.config,
               context.now,
               context.fetch_predictions_fn,
               context.fetch_location_context_fn,
               fn _ -> :error end,
               context.fetch_empty_alerts_fn
             ) == []

      assert crowding_widget_instances(
               context.config,
               context.now,
               context.fetch_predictions_fn,
               context.fetch_location_context_fn,
               context.fetch_parent_stop_id_fn,
               fn _ -> :error end
             ) == []
    end

    test "returns empty if widget is disabled", %{config: config} do
      config = disable_widget(config)

      assert crowding_widget_instances(config) == []
    end
  end
end
