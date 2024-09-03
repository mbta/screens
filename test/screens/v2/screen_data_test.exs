defmodule Screens.V2.ScreenDataTest do
  use ExUnit.Case, async: true

  alias Screens.V2.ScreenData
  alias Screens.V2.WidgetInstance.MockWidget

  describe "serialize/1" do
    test "serializes a hierarchical layout" do
      layout =
        {:screen,
         {:normal,
          [
            :main_content,
            {:flex_zone, {:two_medium, [:medium_left, :medium_right]}},
            :footer
          ]}}

      selected_widgets = %{
        main_content: %MockWidget{
          slot_names: [:main_content],
          widget_type: :departures,
          content: []
        },
        medium_left: %MockWidget{
          slot_names: [:medium_left, :medium_right],
          widget_type: :static_image,
          content: "face_covering.png"
        },
        medium_right: %MockWidget{
          slot_names: [:medium_left, :medium_right],
          widget_type: :static_image,
          content: "autopay.png"
        },
        footer: %MockWidget{
          slot_names: [:footer],
          widget_type: :normal_footer,
          content: "fare info"
        }
      }

      paging_metadata = %{flex_zone: {1, 3}, footer: {0, 2}}

      expected = %{
        type: :normal,
        main_content: %{type: :departures, content: []},
        flex_zone: %{
          type: :two_medium,
          page_index: 1,
          num_pages: 3,
          medium_left: %{type: :static_image, content: "face_covering.png"},
          medium_right: %{type: :static_image, content: "autopay.png"}
        },
        footer: %{type: :normal_footer, page_index: 0, num_pages: 2, content: "fare info"}
      }

      assert expected == ScreenData.serialize({layout, selected_widgets, paging_metadata})
    end
  end
end
