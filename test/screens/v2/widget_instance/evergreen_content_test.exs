defmodule Screens.V2.WidgetInstance.EvergreenContentTest do
  use ExUnit.Case, async: true

  alias Screens.V2.WidgetInstance
  alias Screens.Config.Screen
  alias Screens.V2.WidgetInstance.EvergreenContent

  setup do
    %{
      widget: %EvergreenContent{
        screen: %Screen{app_params: nil, vendor: nil, device_id: nil, name: nil, app_id: nil},
        slot_names: [:medium_left, :medium_right],
        asset_url: "https://mbta-screens.s3.amazonaws.com/screens-dev/videos/some-video.mp4",
        priority: [2, 3, 1]
      }
    }
  end

  describe "priority/1" do
    test "returns priority defined on the struct", %{widget: widget} do
      assert [2, 3, 1] == WidgetInstance.priority(widget)
    end
  end

  describe "serialize/1" do
    test "returns asset url in a map", %{widget: widget} do
      assert %{
               asset_url:
                 "https://mbta-screens.s3.amazonaws.com/screens-dev/videos/some-video.mp4"
             } == WidgetInstance.serialize(widget)
    end
  end

  describe "slot_names/1" do
    test "returns slot names defined on the struct", %{widget: widget} do
      assert [:medium_left, :medium_right] == WidgetInstance.slot_names(widget)
    end
  end

  describe "widget_type/1" do
    test "returns :evergreen_content", %{widget: widget} do
      assert :evergreen_content == WidgetInstance.widget_type(widget)
    end
  end

  describe "valid_candidate?/1" do
    test "returns true", %{widget: widget} do
      assert WidgetInstance.valid_candidate?(widget)
    end
  end
end
