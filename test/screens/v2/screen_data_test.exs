defmodule Screens.V2.ScreenDataTest do
  use ExUnit.Case, async: true

  alias Screens.V2.WidgetInstance.{Departures, StaticImage}

  describe "pick_instances/2" do
    test "chooses the expected template and instance placement" do
      candidate_template =
        {:flex_zone,
         %{
           one_large: [:large],
           two_medium: [:medium_left, :medium_right],
           one_medium_two_small: [:medium_left, :small_upper_right, :small_lower_right]
         }}

      candidate_instances = [
        %StaticImage{size: :small, priority: [4], image_url: "4"},
        %StaticImage{size: :small, priority: [1], image_url: "1"},
        %StaticImage{size: :medium, priority: [3], image_url: "3"},
        %StaticImage{size: :small, priority: [2], image_url: "2"}
      ]

      {actual_layout, actual_instance_placement} =
        Screens.V2.ScreenData.pick_instances(candidate_template, candidate_instances)

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

  describe "serialize/1" do
    test "serializes a hierarchical layout" do
      layout =
        {:screen,
         {:normal,
          [
            :main_content,
            {:flex_zone, {:two_medium, [:medium_left, :medium_right]}}
          ]}}

      selected_widgets = %{
        main_content: %Departures{predictions: []},
        medium_left: %StaticImage{image_url: "face_covering.png", size: :medium},
        medium_right: %StaticImage{image_url: "autopay.png", size: :medium}
      }

      expected = %{
        type: :normal,
        main_content: %{type: :departures, departures: []},
        flex_zone: %{
          type: :two_medium,
          medium_left: %{type: :static_image, url: "face_covering.png"},
          medium_right: %{type: :static_image, url: "autopay.png"}
        }
      }

      assert expected == Screens.V2.ScreenData.serialize({layout, selected_widgets})
    end
  end
end
