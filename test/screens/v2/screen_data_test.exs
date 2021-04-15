defmodule Screens.V2.ScreenDataTest do
  use ExUnit.Case, async: true

  alias Screens.V2.WidgetInstance.MockWidget

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
        %MockWidget{
          slot_names: [:small_upper_right, :small_lower_right],
          priority: [4],
          content: "4"
        },
        %MockWidget{
          slot_names: [:small_upper_right, :small_lower_right],
          priority: [1],
          content: "1"
        },
        %MockWidget{slot_names: [:medium_left, :medium_right], priority: [3], content: "3"},
        %MockWidget{
          slot_names: [:small_upper_right, :small_lower_right],
          priority: [2],
          content: "2"
        }
      ]

      {actual_layout, actual_instance_placement} =
        Screens.V2.ScreenData.pick_instances(candidate_template, candidate_instances)

      assert {:flex_zone,
              {:one_medium_two_small, [:medium_left, :small_upper_right, :small_lower_right]}} ==
               actual_layout

      assert %{
               medium_left: %MockWidget{content: "3"},
               small_lower_right: %MockWidget{content: "2"},
               small_upper_right: %MockWidget{content: "1"}
             } = actual_instance_placement
    end

    test "handles paged regions correctly, and places higher-priority instances in earlier pages" do
      candidate_template =
        {:screen,
         %{
           normal: [
             :header,
             {{0, :flex_zone},
              %{
                one_large: [{0, :large}],
                two_medium: [{0, :medium_left}, {0, :medium_right}],
                one_medium_two_small: [
                  {0, :medium_left},
                  {0, :small_upper_right},
                  {0, :small_lower_right}
                ]
              }},
             {{1, :flex_zone},
              %{
                one_large: [{1, :large}],
                two_medium: [{1, :medium_left}, {1, :medium_right}],
                one_medium_two_small: [
                  {1, :medium_left},
                  {1, :small_upper_right},
                  {1, :small_lower_right}
                ]
              }}
           ],
           takeover: [:full_screen]
         }}

      candidate_instances = [
        %MockWidget{
          slot_names: [:small_upper_right, :small_lower_right],
          priority: [4],
          content: "4"
        },
        %MockWidget{
          slot_names: [:small_upper_right, :small_lower_right],
          priority: [1],
          content: "1"
        },
        %MockWidget{slot_names: [:medium_left, :medium_right], priority: [3], content: "3"},
        %MockWidget{
          slot_names: [:small_upper_right, :small_lower_right],
          priority: [2],
          content: "2"
        },
        %MockWidget{slot_names: [:large], priority: [2], content: "5"},
        %MockWidget{slot_names: [:header], priority: [2], content: "header"}
      ]

      {actual_layout, actual_instance_placement} =
        Screens.V2.ScreenData.pick_instances(candidate_template, candidate_instances)

      assert {:screen,
              {:normal,
               [
                 :header,
                 {{0, :flex_zone},
                  {:one_medium_two_small,
                   [{0, :medium_left}, {0, :small_upper_right}, {0, :small_lower_right}]}},
                 {{1, :flex_zone}, {:one_large, [{1, :large}]}}
               ]}} == actual_layout

      assert %{
               :header => %MockWidget{content: "header"},
               {0, :medium_left} => %MockWidget{content: "3"},
               {0, :small_lower_right} => %MockWidget{content: "2"},
               {0, :small_upper_right} => %MockWidget{content: "1"},
               {1, :large} => %MockWidget{content: "5"}
             } = actual_instance_placement
    end

    test "prefers to place as many instances as possible, priority allowing" do
      candidate_template =
        {:screen,
         %{
           normal_flex_zone: [
             {{0, :flex_zone}, %{one_large: [{0, :large}]}},
             {{1, :flex_zone}, %{one_large: [{1, :large}]}}
           ],
           takeover_flex_zone: [:large_takeover]
         }}

      # We expect the high-priority instance to be placed in the first page rather than
      # the takeover slot, because that allows the second widget to be placed.
      candidate_instances = [
        %MockWidget{slot_names: [:large], priority: [2], content: "2"},
        %MockWidget{slot_names: [:large_takeover, :large], priority: [1], content: "1"}
      ]

      {actual_layout, actual_instance_placement} =
        Screens.V2.ScreenData.pick_instances(candidate_template, candidate_instances)

      assert {:screen,
              {:normal_flex_zone,
               [
                 {{0, :flex_zone}, {:one_large, [{0, :large}]}},
                 {{1, :flex_zone}, {:one_large, [{1, :large}]}}
               ]}} == actual_layout

      assert %{{0, :large} => %MockWidget{content: "1"}, {1, :large} => %MockWidget{content: "2"}} =
               actual_instance_placement
    end

    test "fills earlier pages first" do
      candidate_template =
        {:screen,
         %{
           normal: [
             {{0, :paged_content1}, %{one_large: [{0, :content1_large}]}},
             {{1, :paged_content1}, %{one_large: [{1, :content1_large}]}},
             {{0, :paged_content2}, %{one_large: [{0, :content2_large}]}},
             {{1, :paged_content2}, %{one_large: [{1, :content2_large}]}}
           ]
         }}

      candidate_instances = [
        %MockWidget{slot_names: [:content1_large, :content2_large], priority: [2], content: "2"},
        %MockWidget{slot_names: [:content1_large, :content2_large], priority: [1], content: "1"},
        %MockWidget{slot_names: [:content1_large, :content2_large], priority: [4], content: "4"},
        %MockWidget{slot_names: [:content1_large, :content2_large], priority: [3], content: "3"}
      ]

      {actual_layout, actual_instance_placement} =
        Screens.V2.ScreenData.pick_instances(candidate_template, candidate_instances)

      assert {:screen,
              {:normal,
               [
                 {{0, :paged_content1}, {:one_large, [{0, :content1_large}]}},
                 {{1, :paged_content1}, {:one_large, [{1, :content1_large}]}},
                 {{0, :paged_content2}, {:one_large, [{0, :content2_large}]}},
                 {{1, :paged_content2}, {:one_large, [{1, :content2_large}]}}
               ]}} == actual_layout

      assert %{
               {0, :content1_large} => %MockWidget{content: "1"},
               {0, :content2_large} => %MockWidget{content: "2"},
               {1, :content1_large} => %MockWidget{content: "3"},
               {1, :content2_large} => %MockWidget{content: "4"}
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
        main_content: %MockWidget{
          slot_names: [:main_content],
          priority: [2],
          widget_type: :departures,
          content: []
        },
        medium_left: %MockWidget{
          slot_names: [:medium_left, :medium_right],
          priority: [2],
          widget_type: :static_image,
          content: "face_covering.png"
        },
        medium_right: %MockWidget{
          slot_names: [:medium_left, :medium_right],
          priority: [2],
          widget_type: :static_image,
          content: "autopay.png"
        }
      }

      expected = %{
        type: :normal,
        main_content: %{type: :departures, content: []},
        flex_zone: %{
          type: :two_medium,
          medium_left: %{type: :static_image, content: "face_covering.png"},
          medium_right: %{type: :static_image, content: "autopay.png"}
        }
      }

      assert expected ==
               Screens.V2.ScreenData.serialize({layout, selected_widgets}, 9_999_999_999)
    end
  end

  describe "sorted_slot_list_intersection/2" do
    test "returns the intersection of two non-paged slot lists" do
      template_slots = [
        :normal_header,
        :departures,
        :medium_left,
        :small_upper_right,
        :small_lower_right,
        :normal_footer
      ]

      instance_slots = [:small_upper_right, :small_lower_right, :departures]

      expected = [:departures, :small_upper_right, :small_lower_right]

      assert expected ==
               Screens.V2.ScreenData.sorted_slot_list_intersection(template_slots, instance_slots)
    end

    test "matches instance slots with all corresponding paged template slots" do
      template_slots = [
        {0, :medium_left},
        {0, :medium_right},
        {1, :medium_left},
        {1, :medium_right}
      ]

      instance_slots = [:medium_right]

      expected = [{0, :medium_right}, {1, :medium_right}]

      assert expected ==
               Screens.V2.ScreenData.sorted_slot_list_intersection(template_slots, instance_slots)
    end

    test "sorts paged slots by their page index and prioritizes non-paged content" do
      template_slots = [
        :normal_header,
        :region_x,
        {0, :region1},
        {1, :region1},
        :divider,
        {0, :region2},
        {1, :region2},
        :normal_footer
      ]

      instance_slots = [:divider, :normal_header, :region_y, :region1, :region2, :normal_footer]

      expected = [
        :normal_header,
        :divider,
        :normal_footer,
        {0, :region1},
        {0, :region2},
        {1, :region1},
        {1, :region2}
      ]

      assert expected ==
               Screens.V2.ScreenData.sorted_slot_list_intersection(template_slots, instance_slots)
    end
  end
end
