defmodule Screens.V2.CandidateGenerator.GlEinkDoubleTest do
  use ExUnit.Case, async: true

  alias Screens.Config
  alias Screens.V2.CandidateGenerator.GlEinkDouble
  alias Screens.V2.WidgetInstance.NormalHeader

  setup do
    config = %Config.Screen{
      app_params: %Config.Gl{
        stop_id: "place-bland",
        platform_id: "70149",
        route_id: "Green-B",
        direction_id: 0
      },
      vendor: :gds,
      device_id: "TEST",
      name: "TEST",
      app_id: :gl_eink_double
    }

    %{config: config}
  end

  describe "screen_template/0" do
    test "returns correct template" do
      assert {:screen,
              %{
                normal: [
                  :header,
                  :main_content,
                  :medium_flex,
                  :footer
                ],
                bottom_takeover: [
                  :header,
                  :main_content,
                  :bottom_screen
                ],
                full_takeover: [:full_screen]
              }} == GlEinkDouble.screen_template()
    end
  end

  describe "candidate_instances/1" do
    test "returns expected header", %{config: config} do
      fetch_destination_fn = fn "Green-B", 0 -> "Boston College" end
      now = ~U[2020-04-06T10:00:00Z]

      expected_header = %NormalHeader{
        screen: config,
        icon: :green_b,
        text: "Boston College",
        time: ~U[2020-04-06T10:00:00Z]
      }

      assert expected_header in GlEinkDouble.candidate_instances(
               config,
               now,
               fetch_destination_fn
             )
    end
  end
end
