defmodule Screens.V2.CandidateGenerator.BusEinkTest do
  use ExUnit.Case, async: true

  alias Screens.Config.{Screen, V2}
  alias Screens.V2.CandidateGenerator.BusEink
  alias Screens.V2.WidgetInstance.{FareInfoFooter, NormalHeader}

  setup do
    config = %Screen{
      app_params: %V2.BusEink{
        departures: %V2.Departures{sections: []},
        header: %V2.Header.CurrentStopId{stop_id: "1722"},
        footer: %V2.Footer{stop_id: "1722"},
        alerts: %V2.Alerts{stop_id: "1722"}
      },
      vendor: :gds,
      device_id: "TEST",
      name: "TEST",
      app_id: :bus_eink_v2
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
                       :main_content,
                       {{0, :flex_zone}, %{one_medium: [{0, :medium}]}},
                       {{1, :flex_zone}, %{one_medium: [{1, :medium}]}},
                       :footer
                     ],
                     body_takeover: [
                       :full_body_top_screen,
                       :full_body_bottom_screen
                     ],
                     bottom_takeover: [
                       :main_content,
                       :full_body_bottom_screen
                     ]
                   }}
                ],
                screen_takeover: [:full_screen]
              }} == BusEink.screen_template()
    end
  end

  describe "candidate_instances/3" do
    test "returns expected header", %{config: config} do
      departures_instances_fn = fn _ -> [] end
      alerts_instances_fn = fn _ -> [] end
      fetch_stop_fn = fn "1722" -> "1624 Blue Hill Ave @ Mattapan Sq" end
      now = ~U[2020-04-06T10:00:00Z]
      evergreen_content_instances_fn = fn _ -> [] end

      actual_instances =
        BusEink.candidate_instances(
          config,
          now,
          fetch_stop_fn,
          departures_instances_fn,
          alerts_instances_fn,
          evergreen_content_instances_fn
        )

      expected_header = %NormalHeader{
        screen: config,
        icon: nil,
        text: "1624 Blue Hill Ave @ Mattapan Sq",
        time: ~U[2020-04-06T10:00:00Z]
      }

      expected_footer = %FareInfoFooter{
        screen: config,
        mode: :bus,
        text: "For real-time predictions and fare purchase locations:",
        url: "mbta.com/stops/1722"
      }

      assert expected_header in actual_instances
      assert expected_footer in actual_instances
    end
  end
end
