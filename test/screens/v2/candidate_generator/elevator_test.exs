defmodule Screens.V2.CandidateGenerator.ElevatorTest do
  use ExUnit.Case, async: true

  alias ScreensConfig.{Screen, V2}
  alias Screens.V2.CandidateGenerator.Elevator

  setup do
    config = %Screen{
      app_id: :elevator_v2,
      app_params: %V2.Elevator{
        elevator_id: "1"
      },
      device_id: "TEST",
      name: "TEST"
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
end
