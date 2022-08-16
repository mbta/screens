defmodule Screens.V2.CandidateGenerator.PreFareTest do
  use ExUnit.Case, async: true

  alias Screens.Config.{Screen, V2}
  alias Screens.V2.CandidateGenerator.PreFare
  alias Screens.V2.WidgetInstance.NormalHeader
  alias Screens.V2.WidgetInstance.AudioOnly.{AlertsIntro, AlertsOutro, ContentSummary}

  setup do
    config = %Screen{
      app_params: %V2.PreFare{
        header: %V2.Header.CurrentStopId{stop_id: "place-gover"},
        elevator_status: %V2.ElevatorStatus{
          parent_station_id: "place-foo",
          platform_stop_ids: []
        },
        full_line_map: [
          %V2.FullLineMap{
            asset_path: "test/path"
          }
        ],
        reconstructed_alert_widget: %V2.Header.CurrentStopId{stop_id: "place-gover"},
        content_summary: %V2.ContentSummary{
          parent_station_id: "place-foo"
        }
      },
      vendor: :gds,
      device_id: "TEST",
      name: "TEST",
      app_id: :pre_fare_v2
    }

    %{config: config}
  end

  describe "screen_template/0" do
    test "returns template" do
      assert {:screen,
              %{
                screen_normal: [
                  :header,
                  {:body,
                   %{
                     body_normal: [
                       body_left: %{
                         body_left_normal: [:main_content_left],
                         body_left_takeover: [:full_body_left]
                       },
                       body_right: %{
                         body_right_normal: [
                           :upper_right,
                           {{0, :lower_right},
                            %{
                              one_large: [{0, :large}],
                              two_medium: [{0, :medium_left}, {0, :medium_right}]
                            }},
                           {{1, :lower_right},
                            %{
                              one_large: [{1, :large}],
                              two_medium: [{1, :medium_left}, {1, :medium_right}]
                            }},
                           {{2, :lower_right},
                            %{
                              one_large: [{2, :large}],
                              two_medium: [{2, :medium_left}, {2, :medium_right}]
                            }},
                           {{3, :lower_right},
                            %{
                              one_large: [{3, :large}],
                              two_medium: [{3, :medium_left}, {3, :medium_right}]
                            }}
                         ],
                         body_right_takeover: [:full_body_right]
                       }
                     ],
                     body_takeover: [:full_body]
                   }}
                ],
                screen_takeover: [:full_screen]
              }} == PreFare.screen_template()
    end
  end

  describe "header_instances/3" do
    test "returns expected header", %{config: config} do
      now = ~U[2020-04-06T10:00:00Z]
      fetch_stop_name_fn = fn _ -> "Test Stop" end

      expected_header = [
        %NormalHeader{
          screen: config,
          icon: nil,
          text: "Test Stop",
          time: ~U[2020-04-06T10:00:00Z]
        }
      ]

      actual_instances =
        PreFare.header_instances(
          config,
          now,
          fetch_stop_name_fn
        )

      assert Enum.all?(expected_header, fn x -> x in actual_instances end)
    end
  end

  describe "audio_only_instances/3" do
    test "returns list containing a ContentSummary widget if we successfully fetch routes serving the home station",
         %{config: config} do
      widgets = []

      fetch_routes_by_stop_fn = fn "place-foo" ->
        {:ok,
         [%{route_id: "Red"}, %{route_id: "Green-B"}, %{route_id: "Green-C"}, %{route_id: "Blue"}]}
      end

      expected_content_summary = %ContentSummary{
        widgets_snapshot: widgets,
        screen: config,
        lines_at_station: [:red, :green, :blue]
      }

      assert expected_content_summary in PreFare.audio_only_instances(
               widgets,
               config,
               fetch_routes_by_stop_fn
             )
    end

    test "returns list without content summary if we fail to fetch routes serving the home station",
         %{
           config: config
         } do
      widgets = []

      fetch_routes_by_stop_fn = fn "place-foo" -> :error end

      refute Enum.any?(
               PreFare.audio_only_instances(widgets, config, fetch_routes_by_stop_fn),
               &match?(%ContentSummary{}, &1)
             )
    end

    test "always returns list containing alerts intro", %{config: config} do
      widgets = []

      fetch_routes_by_stop_fn = fn "place-foo" -> {:ok, []} end

      assert Enum.any?(
               PreFare.audio_only_instances(widgets, config, fetch_routes_by_stop_fn),
               &match?(%AlertsIntro{}, &1)
             )
    end

    test "always returns list containing alerts outro", %{config: config} do
      widgets = []

      fetch_routes_by_stop_fn = fn "place-foo" -> {:ok, []} end

      assert Enum.any?(
               PreFare.audio_only_instances(widgets, config, fetch_routes_by_stop_fn),
               &match?(%AlertsOutro{}, &1)
             )
    end
  end
end
