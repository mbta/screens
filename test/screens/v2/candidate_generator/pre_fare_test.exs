defmodule Screens.V2.CandidateGenerator.PreFareTest do
  use ExUnit.Case, async: true

  alias Screens.V2.CandidateGenerator.PreFare
  alias Screens.V2.WidgetInstance.NormalHeader
  alias Screens.V2.WidgetInstance.AudioOnly.{AlertsIntro, AlertsOutro, ContentSummary}
  alias ScreensConfig, as: Config
  alias ScreensConfig.Screen

  setup do
    config = %Screen{
      app_params: %Screen.PreFare{
        header: %Config.Header.CurrentStopId{stop_id: "place-gover"},
        elevator_status: %Config.ElevatorStatus{
          parent_station_id: "place-foo",
          platform_stop_ids: []
        },
        full_line_map: [
          %Config.FullLineMap{
            asset_path: "test/path"
          }
        ],
        reconstructed_alert_widget: %Config.Header.CurrentStopId{stop_id: "place-gover"},
        content_summary: %Config.ContentSummary{
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

  describe "screen_template/1" do
    @body_right %{
      body_right_normal: [
        {{0, :upper_right},
         %{
           one_large: [{0, :large}],
           two_medium: [{0, :medium_left}, {0, :medium_right}]
         }},
        {{1, :upper_right},
         %{
           one_large: [{1, :large}],
           two_medium: [{1, :medium_left}, {1, :medium_right}]
         }},
        {{2, :upper_right},
         %{
           one_large: [{2, :large}],
           two_medium: [{2, :medium_left}, {2, :medium_right}]
         }},
        {{3, :upper_right},
         %{
           one_large: [{3, :large}],
           two_medium: [{3, :medium_left}, {3, :medium_right}]
         }},
        :lower_right
      ],
      body_right_takeover: [:full_body_right],
      body_right_surge: [:orange_line_surge_upper, :orange_line_surge_lower]
    }

    test "returns duo template", %{config: config} do
      assert {:screen,
              %{
                screen_normal: [
                  :header,
                  {:body,
                   %{
                     body_normal: [
                       body_left: %{
                         body_left_normal: [:main_content_left],
                         body_left_takeover: [:full_body_left],
                         body_left_flex: [
                           {0, :paged_main_content_left},
                           {1, :paged_main_content_left},
                           {2, :paged_main_content_left},
                           {3, :paged_main_content_left}
                         ]
                       },
                       body_right: @body_right
                     ],
                     body_takeover: [:full_body_duo]
                   }}
                ],
                screen_takeover: [:full_duo_screen],
                screen_split_takeover: [:full_left_screen, :full_right_screen]
              }} == PreFare.screen_template(config)
    end

    test "returns solo template", %{config: config} do
      assert {:screen,
              %{
                screen_normal: [:header, {:body, %{body_normal: [body_right: @body_right]}}],
                screen_split_takeover: [:full_right_screen]
              }} == PreFare.screen_template(put_in(config.app_params.template, :solo))
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

      routes_fetch_fn = fn %{stop_id: "place-foo"} ->
        {:ok, [%{id: "Red"}, %{id: "Green-B"}, %{id: "Green-C"}, %{id: "Blue"}]}
      end

      expected_content_summary = %ContentSummary{
        widgets_snapshot: widgets,
        screen: config,
        lines_at_station: [:red, :green, :blue]
      }

      assert expected_content_summary in PreFare.audio_only_instances(
               widgets,
               config,
               routes_fetch_fn
             )
    end

    test "returns list without content summary if we fail to fetch routes serving the home station",
         %{
           config: config
         } do
      widgets = []

      routes_fetch_fn = fn %{stop_id: "place-foo"} -> :error end

      refute Enum.any?(
               PreFare.audio_only_instances(widgets, config, routes_fetch_fn),
               &match?(%ContentSummary{}, &1)
             )
    end

    test "always returns list containing alerts intro", %{config: config} do
      widgets = []

      routes_fetch_fn = fn %{stop_id: "place-foo"} -> {:ok, []} end

      assert Enum.any?(
               PreFare.audio_only_instances(widgets, config, routes_fetch_fn),
               &match?(%AlertsIntro{}, &1)
             )
    end

    test "always returns list containing alerts outro", %{config: config} do
      widgets = []

      routes_fetch_fn = fn %{stop_id: "place-foo"} -> {:ok, []} end

      assert Enum.any?(
               PreFare.audio_only_instances(widgets, config, routes_fetch_fn),
               &match?(%AlertsOutro{}, &1)
             )
    end
  end
end
