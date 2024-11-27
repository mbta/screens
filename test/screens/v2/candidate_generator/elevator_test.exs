defmodule Screens.V2.CandidateGenerator.ElevatorTest do
  use ExUnit.Case, async: true

  alias ScreensConfig.{Screen, V2}
  alias Screens.V2.CandidateGenerator.Elevator
  alias Screens.V2.WidgetInstance.ElevatorClosures

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
                normal: [:main_content]
              }} == Elevator.screen_template()
    end
  end

  describe "candidate_instances/4" do
    test "returns expected content", %{config: config} do
      now = ~U[2020-04-06T10:00:00Z]
      elevator_instances = [struct(ElevatorClosures)]
      elevator_closure_instances_fn = fn _, _ -> elevator_instances end
      evergreen_content_instances_fn = fn _, _ -> [] end

      assert elevator_instances ==
               Elevator.candidate_instances(
                 config,
                 now,
                 elevator_closure_instances_fn,
                 evergreen_content_instances_fn
               )
    end
  end
end
