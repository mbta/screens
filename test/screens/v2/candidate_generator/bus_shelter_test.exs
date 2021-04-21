defmodule Screens.V2.CandidateGenerator.BusShelterTest do
  use ExUnit.Case, async: true

  alias Screens.Config
  alias Screens.V2.CandidateGenerator.BusShelter
  alias Screens.V2.WidgetInstance.{LinkFooter, NormalHeader}

  setup do
    config = %Config.Screen{
      app_params: %Config.BusShelter{stop_id: "1216"},
      vendor: :lg_mri,
      device_id: "TEST",
      name: "TEST",
      app_id: :bus_shelter
    }

    %{config: config}
  end

  describe "screen_template/0" do
    test "returns template" do
      assert {:screen,
              %{
                normal: [
                  :header,
                  :main_content,
                  {:flex_zone,
                   %{
                     one_large: [:large],
                     one_medium_two_small: [:medium_left, :small_upper_right, :small_lower_right],
                     two_medium: [:medium_left, :medium_right]
                   }},
                  :footer
                ],
                takeover: [:full_screen]
              }} == BusShelter.screen_template()
    end
  end

  describe "candidate_instances/3" do
    test "returns expected header and footer", %{config: config} do
      fetch_stop_fn = fn "1216" -> "Columbus Ave @ Dimock St" end
      now = ~U[2020-04-06T10:00:00Z]

      expected_header = %NormalHeader{
        screen: config,
        icon: nil,
        text: "Columbus Ave @ Dimock St",
        time: ~U[2020-04-06T10:00:00Z]
      }

      expected_footer = %LinkFooter{screen: config, text: "More at", url: "mbta.com/stops/1216"}

      actual_instances = BusShelter.candidate_instances(config, now, fetch_stop_fn)

      assert expected_header in actual_instances
      assert expected_footer in actual_instances
    end
  end
end
