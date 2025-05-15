defmodule Screens.V2.CandidateGenerator.BusEinkTest do
  use ExUnit.Case, async: true

  alias Screens.V2.CandidateGenerator.BusEink
  alias Screens.V2.WidgetInstance.{BottomScreenFiller, FareInfoFooter}
  alias ScreensConfig, as: Config
  alias ScreensConfig.Screen

  setup do
    config = %Screen{
      app_params: %Screen.BusEink{
        departures: %Config.Departures{sections: []},
        header: %Config.Header.StopId{stop_id: "1722"},
        footer: %Config.Footer{stop_id: "1722"},
        alerts: %Config.Alerts{stop_id: "1722"}
      },
      vendor: :gds,
      device_id: "TEST",
      name: "TEST",
      app_id: :bus_eink_v2
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
                     ],
                     flex_zone_takeover: [:main_content, :flex_zone_takeover, :footer]
                   }}
                ],
                screen_takeover: [:full_screen]
              }} == BusEink.screen_template(config)
    end
  end

  describe "candidate_instances/7" do
    test "returns expected instances", %{config: config} do
      now = ~U[2020-04-06T10:00:00Z]
      header_instances_fn = fn ^config, ^now -> [:header] end
      departures_instances_fn = fn ^config, ^now -> [:departures] end
      alerts_instances_fn = fn ^config, ^now -> [:alert] end
      evergreen_content_instances_fn = fn ^config, ^now -> [:evergreen] end
      subway_status_instances_fn = fn ^config, ^now -> [:status] end

      actual_instances =
        BusEink.candidate_instances(
          config,
          now,
          header_instances_fn,
          departures_instances_fn,
          alerts_instances_fn,
          evergreen_content_instances_fn,
          subway_status_instances_fn
        )

      assert [
               :alert,
               :departures,
               :evergreen,
               :header,
               :status,
               %BottomScreenFiller{},
               %FareInfoFooter{}
             ] = Enum.sort(actual_instances)
    end
  end
end
