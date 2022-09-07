defmodule Screens.V2.CandidateGenerator.GlEinkTest do
  use ExUnit.Case, async: true

  alias Screens.Config.{Screen, V2}
  alias Screens.V2.CandidateGenerator.GlEink
  alias Screens.V2.WidgetInstance.{FareInfoFooter, NormalHeader}

  setup do
    config = %Screen{
      app_params: %V2.GlEink{
        departures: %V2.Departures{sections: []},
        header: %V2.Header.Destination{route_id: "Green-C", direction_id: 0},
        footer: %V2.Footer{stop_id: "1722"},
        alerts: %V2.Alerts{stop_id: "1722"},
        line_map: %V2.LineMap{
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

  describe "screen_template/0" do
    test "returns correct template" do
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
                     ]
                   }}
                ],
                screen_takeover: [:full_screen]
              }} == GlEink.screen_template()
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
      actual_instances = GlEink.footer_instances(config)

      expected_footer = %FareInfoFooter{
        screen: config,
        mode: :subway,
        text: "For real-time predictions and fare purchase locations:",
        url: "mbta.com/stops/1722"
      }

      assert expected_footer in actual_instances
    end
  end
end
