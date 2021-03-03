defmodule Screens.V2.ScreenDataTest do
  use ExUnit.Case, async: true

  alias Screens.V2.WidgetInstance.StaticImage

  describe "pick_instances/2" do
    test "chooses the expected template and instance placement" do
      candidate_templates = [
        {[:large], {:flex_zone, {:one_large, [:large]}}},
        {[:medium_left, :small_upper_right, :small_lower_right],
         {:flex_zone,
          {:one_medium_two_small, [:medium_left, :small_upper_right, :small_lower_right]}}},
        {[:medium_left, :medium_right],
         {:flex_zone, {:two_medium, [:medium_left, :medium_right]}}}
      ]

      candidate_instances = [
        %StaticImage{size: :small, priority: [4], image_url: "4"},
        %StaticImage{size: :small, priority: [1], image_url: "1"},
        %StaticImage{size: :medium, priority: [3], image_url: "3"},
        %StaticImage{size: :small, priority: [2], image_url: "2"}
      ]

      {actual_layout, actual_instance_placement} =
        Screens.V2.ScreenData.pick_instances(candidate_templates, candidate_instances)

      assert {:flex_zone,
              {:one_medium_two_small, [:medium_left, :small_upper_right, :small_lower_right]}} ==
               actual_layout

      assert %{
               medium_left: %StaticImage{size: :medium, priority: [3], image_url: "3"},
               small_lower_right: %StaticImage{size: :small, priority: [2], image_url: "2"},
               small_upper_right: %StaticImage{size: :small, priority: [1], image_url: "1"}
             } = actual_instance_placement
    end
  end
end
