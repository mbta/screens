defmodule Screens.V2.TemplateTest do
  use ExUnit.Case, async: true

  alias Screens.V2.Template

  describe "with_paging/2" do
    """
    You left off on writing tests!
    But also!!! the type defs aren't quite correct!!!!!
    Paging introduces lists of index+template tuples!!!!!!!
    """

    test "handles atom correctly" do
      template = :header

      assert [{0, :header}, {1, :header}] = Template.with_paging(template, 2)
    end

    test "handles map correctly" do
      template =
        {:flex_zone,
         %{
           one_large: [:large],
           two_medium: [
             :medium_left,
             {:medium_right,
              %{
                child_slot1: [:child_a, :child_b],
                child_slot2: [:child_c]
              }}
           ]
         }}

      num_pages = 2

      expected = [
        {{0, :flex_zone},
         %{
           one_large: [{0, :large}],
           two_medium: [
             {0, :medium_left},
             {{0, :medium_right},
              %{
                child_slot1: [{0, :child_a}, {0, :child_b}],
                child_slot2: [{0, :child_c}]
              }}
           ]
         }},
        {{1, :flex_zone},
         %{
           one_large: [{1, :large}],
           two_medium: [
             {1, :medium_left},
             {{1, :medium_right},
              %{
                child_slot1: [{1, :child_a}, {1, :child_b}],
                child_slot2: [{1, :child_c}]
              }}
           ]
         }}
      ]

      assert expected == Template.with_paging(template, num_pages)
    end

    test "rejects paged templates" do
      paged_template = [{0, :header}, {1, :header}]

      assert_raise FunctionClauseError, fn -> Template.with_paging(paged_template, 2) end
    end
  end

  describe "slot_combinations/1" do
    test "handles atom correctly" do
      assert [{slot_id_list, layout}] = Template.slot_combinations(:header)
      assert [:header] == slot_id_list
      assert :header == layout
    end

    test "handles map correctly" do
      template =
        {:flex_zone,
         %{
           one_large: [:large],
           two_medium: [:medium_left, :medium_right],
           one_medium_two_small: [:medium_left, :small_upper_right, :small_lower_right]
         }}

      expected = [
        {[:large], {:flex_zone, {:one_large, [:large]}}},
        {[:medium_left, :small_upper_right, :small_lower_right],
         {:flex_zone,
          {:one_medium_two_small, [:medium_left, :small_upper_right, :small_lower_right]}}},
        {[:medium_left, :medium_right],
         {:flex_zone, {:two_medium, [:medium_left, :medium_right]}}}
      ]

      assert expected == Template.slot_combinations(template)
    end

    test "handles nested maps correctly" do
      template =
        {:screen,
         %{
           normal: [
             :header,
             :main_content,
             {:flex_zone,
              %{
                one_large: [:large],
                one_medium_two_small: [:medium_left, :small_upper_right, :small_lower_right],
                two_medium: [:medium_left, :medium_right]
              }},
             :footer
           ],
           takeover: [:fullscreen]
         }}

      expected = [
        {[:header, :main_content, :large, :footer],
         {:screen,
          {:normal, [:header, :main_content, {:flex_zone, {:one_large, [:large]}}, :footer]}}},
        {[:header, :main_content, :medium_left, :small_upper_right, :small_lower_right, :footer],
         {:screen,
          {:normal,
           [
             :header,
             :main_content,
             {:flex_zone,
              {:one_medium_two_small, [:medium_left, :small_upper_right, :small_lower_right]}},
             :footer
           ]}}},
        {[:header, :main_content, :medium_left, :medium_right, :footer],
         {:screen,
          {:normal,
           [
             :header,
             :main_content,
             {:flex_zone, {:two_medium, [:medium_left, :medium_right]}},
             :footer
           ]}}},
        {[:fullscreen], {:screen, {:takeover, [:fullscreen]}}}
      ]

      assert expected == Template.slot_combinations(template)
    end

    test "handles multiple nested maps correctly" do
      flex_zone = %{
        one_large: [:large],
        two_medium: [:medium_left, :medium_right]
      }

      template =
        {:screen,
         %{
           normal: [{:flex_a, flex_zone}, {:flex_b, flex_zone}]
         }}

      expected = [
        {[:large, :large],
         {:screen, {:normal, [flex_a: {:one_large, [:large]}, flex_b: {:one_large, [:large]}]}}},
        {[:medium_left, :medium_right, :large],
         {:screen,
          {:normal,
           [flex_a: {:two_medium, [:medium_left, :medium_right]}, flex_b: {:one_large, [:large]}]}}},
        {[:large, :medium_left, :medium_right],
         {:screen,
          {:normal,
           [flex_a: {:one_large, [:large]}, flex_b: {:two_medium, [:medium_left, :medium_right]}]}}},
        {[:medium_left, :medium_right, :medium_left, :medium_right],
         {:screen,
          {:normal,
           [
             flex_a: {:two_medium, [:medium_left, :medium_right]},
             flex_b: {:two_medium, [:medium_left, :medium_right]}
           ]}}}
      ]

      assert expected == Template.slot_combinations(template)
    end
  end

  describe "position_widget_instances/2" do
    test "handles nested maps correctly" do
      layout =
        {:screen,
         {:normal,
          [
            :header,
            :main_content,
            {:flex_zone, {:two_medium, [:medium_left, :medium_right]}},
            :footer
          ]}}

      selected_widgets = %{
        header: %{type: :header, current_time: "12:34"},
        main_content: %{type: :departures, rows: []},
        medium_left: %{type: :alert, route: "44"},
        medium_right: %{type: :static_image, url: "img.png"},
        footer: %{type: :footer, url: "mbta.com/stops/123"}
      }

      expected = %{
        type: :normal,
        header: %{type: :header, current_time: "12:34"},
        main_content: %{type: :departures, rows: []},
        flex_zone: %{
          type: :two_medium,
          medium_left: %{type: :alert, route: "44"},
          medium_right: %{type: :static_image, url: "img.png"}
        },
        footer: %{type: :footer, url: "mbta.com/stops/123"}
      }

      assert expected == Template.position_widget_instances(layout, selected_widgets)
    end
  end
end
