defmodule Screens.V2.CandidateGenerator.BusShelterTest do
  use ExUnit.Case, async: true

  alias Screens.V2.CandidateGenerator.BusShelter
  alias Screens.V2.WidgetInstance.{LinkFooter, Survey}
  alias ScreensConfig, as: Config
  alias ScreensConfig.Screen

  setup do
    config = %Screen{
      app_params: %Screen.BusShelter{
        departures: %Config.Departures{sections: []},
        header: %Config.Header.StopId{stop_id: "1216"},
        footer: %Config.Footer{stop_id: "1216"},
        alerts: %Config.Alerts{stop_id: "1216"}
      },
      vendor: :lg_mri,
      device_id: "TEST",
      name: "TEST",
      app_id: :bus_shelter_v2
    }

    %{config: config}
  end

  describe "screen_template/1" do
    test "returns template", %{config: config} do
      assert {:screen,
              %{
                screen_normal: [
                  :header,
                  {:body,
                   %{
                     body_normal: [
                       :main_content,
                       {{0, :flex_zone},
                        %{
                          one_large: [{0, :large}],
                          one_medium_two_small: [
                            {0, :medium_left},
                            {0, :small_upper_right},
                            {0, :small_lower_right}
                          ],
                          two_medium: [{0, :medium_left}, {0, :medium_right}]
                        }},
                       {{1, :flex_zone},
                        %{
                          one_large: [{1, :large}],
                          one_medium_two_small: [
                            {1, :medium_left},
                            {1, :small_upper_right},
                            {1, :small_lower_right}
                          ],
                          two_medium: [{1, :medium_left}, {1, :medium_right}]
                        }},
                       {{2, :flex_zone},
                        %{
                          one_large: [{2, :large}],
                          one_medium_two_small: [
                            {2, :medium_left},
                            {2, :small_upper_right},
                            {2, :small_lower_right}
                          ],
                          two_medium: [{2, :medium_left}, {2, :medium_right}]
                        }},
                       :footer
                     ],
                     body_takeover: [:full_body]
                   }}
                ],
                screen_takeover: [:full_screen]
              }} == BusShelter.screen_template(config)
    end
  end

  describe "candidate_instances/7" do
    test "returns expected instances", %{config: config} do
      now = ~U[2020-04-06T10:00:00Z]
      header_instances_fn = fn ^config, ^now -> [:header] end
      departures_instances_fn = fn ^config, ^now -> [:departures] end
      alert_instances_fn = fn ^config, ^now -> [:alert] end
      evergreen_content_instances_fn = fn ^config, ^now -> [:evergreen] end
      subway_status_instances_fn = fn ^config, ^now -> [:status] end

      actual_instances =
        BusShelter.candidate_instances(
          config,
          now,
          header_instances_fn,
          departures_instances_fn,
          alert_instances_fn,
          evergreen_content_instances_fn,
          subway_status_instances_fn
        )

      assert [:alert, :departures, :evergreen, :header, :status, %LinkFooter{}, %Survey{}] =
               Enum.sort(actual_instances)
    end
  end
end
