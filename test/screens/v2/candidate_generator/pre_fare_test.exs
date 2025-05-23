defmodule Screens.V2.CandidateGenerator.PreFareTest do
  use ExUnit.Case, async: true

  alias Screens.V2.CandidateGenerator.PreFare
  alias Screens.V2.WidgetInstance.AudioOnly.{AlertsIntro, AlertsOutro, ContentSummary}
  alias Screens.V2.WidgetInstance.MockWidget
  alias ScreensConfig, as: Config
  alias ScreensConfig.Screen

  setup do
    config = %Screen{
      app_params: %Screen.PreFare{
        header: %Config.Header.StopId{stop_id: "place-gover"},
        elevator_status: %Config.ElevatorStatus{
          parent_station_id: "place-foo",
          platform_stop_ids: []
        },
        full_line_map: [
          %Config.FullLineMap{
            asset_path: "test/path"
          }
        ],
        reconstructed_alert_widget: %Config.Alerts{stop_id: "place-gover"},
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
      body_right_takeover: [:full_body_right]
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

  describe "audio_only_instances/3" do
    @takeover_widget %MockWidget{
      slot_names: [:full_body_duo],
      audio_sort_key: [0],
      audio_valid_candidate?: true
    }

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

    test "does not include content summary when there is a widget in a takeover slot",
         %{config: config} do
      widgets = [@takeover_widget]
      routes_fetch_fn = fn %{stop_id: "place-foo"} -> {:ok, []} end

      refute Enum.any?(
               PreFare.audio_only_instances(widgets, config, routes_fetch_fn),
               &match?(%ContentSummary{}, &1)
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

    test "normally returns list containing alerts intro", %{config: config} do
      widgets = []
      routes_fetch_fn = fn %{stop_id: "place-foo"} -> {:ok, []} end

      assert Enum.any?(
               PreFare.audio_only_instances(widgets, config, routes_fetch_fn),
               &match?(%AlertsIntro{}, &1)
             )
    end

    test "does not include alerts intro when there is a widget in a takeover slot",
         %{config: config} do
      widgets = [@takeover_widget]
      routes_fetch_fn = fn %{stop_id: "place-foo"} -> {:ok, []} end

      refute Enum.any?(
               PreFare.audio_only_instances(widgets, config, routes_fetch_fn),
               &match?(%AlertsIntro{}, &1)
             )
    end

    test "always returns list containing alerts outro", %{config: config} do
      widgets = [@takeover_widget]
      routes_fetch_fn = fn %{stop_id: "place-foo"} -> {:ok, []} end

      assert Enum.any?(
               PreFare.audio_only_instances(widgets, config, routes_fetch_fn),
               &match?(%AlertsOutro{}, &1)
             )
    end
  end
end
