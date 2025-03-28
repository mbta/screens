defmodule Screens.V2.CandidateGenerator.ElevatorTest do
  use ExUnit.Case, async: true

  alias Screens.V2.CandidateGenerator.Elevator
  alias Screens.V2.ScreenData.QueryParams
  alias ScreensConfig.Screen

  setup do
    config = %Screen{
      app_id: :elevator_v2,
      app_params: %Screen.Elevator{
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

  describe "screen_template/1" do
    test "returns template", %{config: config} do
      assert {:screen,
              %{
                normal: [:header, :main_content, :footer],
                takeover: [:full_screen]
              }} == Elevator.screen_template(config)
    end
  end

  describe "candidate_instances/3" do
    test "calls instance generator functions and combines the results", %{config: config} do
      now = ~U[2020-04-06T10:00:00Z]
      query_params = %QueryParams{}

      instance_fns = [
        fn ^config, ^now -> ~w[one two]a end,
        fn ^config, ^now -> ~w[three]a end
      ]

      assert Elevator.candidate_instances(config, query_params, now, instance_fns) ==
               ~w[one two three]a
    end
  end
end
