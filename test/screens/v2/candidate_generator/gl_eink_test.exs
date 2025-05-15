defmodule Screens.V2.CandidateGenerator.GlEinkTest do
  use ExUnit.Case, async: true

  alias Screens.V2.CandidateGenerator.GlEink
  alias Screens.V2.WidgetInstance.{FareInfoFooter, NormalHeader}
  alias ScreensConfig, as: Config
  alias ScreensConfig.Screen

  setup do
    config = %Screen{
      app_params: %Screen.GlEink{
        departures: %Config.Departures{sections: []},
        header: %Config.Header.Destination{route_id: "Green-C", direction_id: 0},
        footer: %Config.Footer{stop_id: "1722"},
        alerts: %Config.Alerts{stop_id: "1722"},
        line_map: %Config.LineMap{
          direction_id: 0,
          route_id: "Green-C",
          station_id: "place-bcnwa",
          stop_id: "1722"
        }
      },
      vendor: :gds,
      device_id: "TEST",
      name: "TEST",
      app_id: :gl_eink_v2
    }

    %{config: config}
  end

  describe "screen_template/1" do
    test "returns correct template", %{config: config} do
      assert {:screen,
              %{
                screen_normal: [
                  :header,
                  {:body,
                   %{
                     body_normal: [
                       :left_sidebar,
                       :main_content,
                       {{0, :flex_zone}, %{one_medium: [{0, :medium}]}},
                       {{1, :flex_zone}, %{one_medium: [{1, :medium}]}},
                       :footer
                     ],
                     top_takeover: [
                       :full_body_top_screen,
                       {{0, :flex_zone}, %{one_medium: [{0, :medium}]}},
                       {{1, :flex_zone}, %{one_medium: [{1, :medium}]}},
                       :footer
                     ],
                     body_takeover: [
                       :full_body_top_screen,
                       :full_body_bottom_screen
                     ],
                     bottom_takeover: [
                       :left_sidebar,
                       :main_content,
                       :full_body_bottom_screen
                     ],
                     top_and_flex_takeover: [:full_body_top_screen, :flex_zone_takeover, :footer],
                     flex_zone_takeover: [
                       :left_sidebar,
                       :main_content,
                       :flex_zone_takeover,
                       :footer
                     ]
                   }}
                ],
                screen_takeover: [:full_screen]
              }} == GlEink.screen_template(config)
    end
  end

  describe "header_instances/3" do
    test "returns expected header", %{config: config} do
      fetch_destination_fn = fn "Green-C", 0 -> "Cleveland Circle" end
      now = ~U[2020-04-06T10:00:00Z]

      actual_instances =
        GlEink.header_instances(
          config,
          now,
          fetch_destination_fn
        )

      expected_header = %NormalHeader{
        screen: config,
        icon: :green_c,
        text: "Cleveland Circle",
        time: ~U[2020-04-06T10:00:00Z]
      }

      assert expected_header in actual_instances
    end
  end

  describe "footer_instances/1" do
    test "returns expected footer", %{config: config} do
      expected_footer = %FareInfoFooter{mode: :subway, stop_id: "1722"}

      assert expected_footer in GlEink.footer_instances(config)
    end
  end
end
