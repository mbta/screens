defmodule Screens.V2.CandidateGenerator.ElevatorTest do
  use ExUnit.Case, async: true

  alias ScreensConfig.{Screen, V2}
  alias Screens.V2.CandidateGenerator.Elevator

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
                normal: [:header, :main_content, :footer],
                takeover: [:full_screen]
              }} == Elevator.screen_template()
    end
  end

  describe "candidate_instances/3" do
    test "calls instance generator functions and combines the results", %{config: config} do
      now = ~U[2020-04-06T10:00:00Z]

      instance_fns = [
        fn ^config, ^now -> ~w[one two]a end,
        fn ^config, ^now -> ~w[three]a end
      ]

      assert Elevator.candidate_instances(config, now, instance_fns) == ~w[one two three]a
    end
  end
end
