defmodule Screens.V2.CandidateGenerator.BusShelterTest do
  use ExUnit.Case, async: true

  alias Screens.Config.{Screen, V2}
  alias Screens.V2.CandidateGenerator.BusShelter
  alias Screens.V2.WidgetInstance.{LinkFooter, NormalHeader}

  setup do
    config = %Screen{
      app_params: %V2.BusShelter{
        departures: %V2.Departures{sections: []},
        header: %V2.Header.CurrentStopId{stop_id: "1216"},
        footer: %V2.Footer{stop_id: "1216"},
        alerts: %V2.Alerts{stop_id: "1216"}
      },
      vendor: :lg_mri,
      device_id: "TEST",
      name: "TEST",
      app_id: :bus_shelter_v2
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
              }} == BusShelter.screen_template()
    end
  end

  describe "candidate_instances/3" do
    test "returns expected header and footer", %{config: config} do
      departures_instances_fn = fn _ -> [] end
      alert_instances_fn = fn _ -> [] end
      fetch_stop_fn = fn "1216" -> "Columbus Ave @ Dimock St" end
      now = ~U[2020-04-06T10:00:00Z]

      expected_header = %NormalHeader{
        screen: config,
        icon: nil,
        text: "Columbus Ave @ Dimock St",
        time: ~U[2020-04-06T10:00:00Z]
      }

      expected_footer = %LinkFooter{screen: config, text: "More at", url: "mbta.com/stops/1216"}

      actual_instances =
        BusShelter.candidate_instances(
          config,
          now,
          fetch_stop_fn,
          departures_instances_fn,
          alert_instances_fn
        )

      assert expected_header in actual_instances
      assert expected_footer in actual_instances
    end
  end
end
