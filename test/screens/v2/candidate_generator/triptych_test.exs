defmodule Screens.V2.CandidateGenerator.TriptychTest do
  use ExUnit.Case, async: true

  alias Screens.Config.{Screen, V2}
  alias Screens.V2.CandidateGenerator.Triptych

  setup do
    config = %Screen{
      app_params: %V2.Triptych{
        evergreen_content: [],
        train_crowding: %V2.TrainCrowding{
          station_id: "place-dwnxg",
          direction_id: 1,
          platform_position: 2.5,
          front_car_direction: "right"
        }
      },
      vendor: :outfront,
      device_id: "TEST",
      name: "TEST",
      app_id: :triptych_v2
    }

    %{config: config}
  end

  describe "screen_template/0" do
    test "returns template" do
      assert {:screen,
              %{
                screen_normal: [:full_screen],
                screen_split: [:first_pane, :second_pane, :third_pane]
              }} == Triptych.screen_template()
    end
  end
end
