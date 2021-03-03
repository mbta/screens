defmodule Screens.V2.TemplateTest do
  use ExUnit.Case, async: true

  alias Screens.V2.Template

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
