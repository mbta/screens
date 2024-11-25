defmodule Screens.V2.CandidateGenerator.ElevatorTest do
  use ExUnit.Case, async: true

  alias ScreensConfig.{Screen, V2}
  alias Screens.V2.CandidateGenerator.Elevator
  alias Screens.V2.WidgetInstance.{Footer, NormalHeader}

  setup do
    config = %Screen{
      app_id: :elevator_v2,
      app_params: %V2.Elevator{
        elevator_id: "1",
        alternate_direction_text: "Test",
        accessible_path_direction_arrow: :n
      },
      device_id: "TEST",
      name: "TEST",
      vendor: :mimo
    }

    %{config: config}
  end

  describe "screen_template/0" do
    test "returns template" do
      assert {:screen,
              %{
                normal: [:header, :main_content, :footer]
              }} == Elevator.screen_template()
    end
  end

  describe "candidate_instances/4" do
    test "returns expected header and footer", %{config: config} do
      now = ~U[2020-04-06T10:00:00Z]
      elevator_closure_instances_fn = fn _ -> [] end
      evergreen_content_instances_fn = fn _, _ -> [] end

      expected_header = %NormalHeader{
        screen: config,
        icon: nil,
        text: "Elevator 1",
        time: now
      }

      expected_footer = %Footer{screen: config}

      actual_instances =
        Elevator.candidate_instances(
          config,
          now,
          elevator_closure_instances_fn,
          evergreen_content_instances_fn
        )

      assert expected_header in actual_instances
      assert expected_footer in actual_instances
    end
  end
end
