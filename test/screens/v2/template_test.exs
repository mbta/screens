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
      template = %{
        one_large: [:large],
        two_medium: [:medium_left, :medium_right],
        one_medium_two_small: [:medium_left, :small_upper_right, :small_lower_right]
      }

      expected = [
        {[:large], {:one_large, [:large]}},
        {[:medium_left, :small_upper_right, :small_lower_right],
         {:one_medium_two_small, [:medium_left, :small_upper_right, :small_lower_right]}},
        {[:medium_left, :medium_right], {:two_medium, [:medium_left, :medium_right]}}
      ]

      assert expected == Template.slot_combinations(template)
    end

    test "handles nested maps correctly" do
      template = %{
        normal: [
          :header,
          :main_content,
          %{
            one_large: [:large],
            one_medium_two_small: [:medium_left, :small_upper_right, :small_lower_right],
            two_medium: [:medium_left, :medium_right]
          },
          :footer
        ],
        takeover: [:fullscreen]
      }

      expected = [
        {[:header, :main_content, :large, :footer],
         {:normal, [:header, :main_content, {:one_large, [:large]}, :footer]}},
        {[:header, :main_content, :medium_left, :small_upper_right, :small_lower_right, :footer],
         {:normal,
          [
            :header,
            :main_content,
            {:one_medium_two_small, [:medium_left, :small_upper_right, :small_lower_right]},
            :footer
          ]}},
        {[:header, :main_content, :medium_left, :medium_right, :footer],
         {:normal,
          [:header, :main_content, {:two_medium, [:medium_left, :medium_right]}, :footer]}},
        {[:fullscreen], {:takeover, [:fullscreen]}}
      ]

      assert expected == Template.slot_combinations(template)
    end

    test "handles multiple nested maps correctly" do
      flex_zone = %{
        one_large: [:large],
        two_medium: [:medium_left, :medium_right]
      }

      template = %{
        normal: [flex_zone, flex_zone]
      }

      expected = [
        {[:large, :large], {:normal, [one_large: [:large], one_large: [:large]]}},
        {[:medium_left, :medium_right, :large],
         {:normal, [two_medium: [:medium_left, :medium_right], one_large: [:large]]}},
        {[:large, :medium_left, :medium_right],
         {:normal, [one_large: [:large], two_medium: [:medium_left, :medium_right]]}},
        {[:medium_left, :medium_right, :medium_left, :medium_right],
         {:normal,
          [two_medium: [:medium_left, :medium_right], two_medium: [:medium_left, :medium_right]]}}
      ]

      assert expected == Template.slot_combinations(template)
    end
  end

  describe "position_widget_instances/2" do
    test "handles nested maps correctly" do
      layout =
        {:normal, [:header, :main_content, {:two_medium, [:medium_left, :medium_right]}, :footer]}

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
        two_medium: %{
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
