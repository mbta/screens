defmodule Screens.V2.WidgetInstance.EvergreenContentTest do
  use ExUnit.Case, async: true

  alias Screens.V2.WidgetInstance
  alias Screens.Config.Screen
  alias Screens.V2.WidgetInstance.EvergreenContent
  alias Screens.Config.V2.Schedule

  setup do
    %{
      widget: %EvergreenContent{
        screen: %Screen{app_params: nil, vendor: nil, device_id: nil, name: nil, app_id: nil},
        slot_names: [:medium_left, :medium_right],
        asset_url: "https://mbta-screens.s3.amazonaws.com/screens-dev/videos/some-video.mp4",
        priority: [2, 3, 1],
        schedule: [%Schedule{}],
        now: ~U[2021-02-01T00:00:00Z]
      },
      widget_old_schedule: %EvergreenContent{
        screen: %Screen{app_params: nil, vendor: nil, device_id: nil, name: nil, app_id: nil},
        slot_names: [:medium_left, :medium_right],
        asset_url: "https://mbta-screens.s3.amazonaws.com/screens-dev/videos/some-video.mp4",
        priority: [2, 3, 1],
        schedule: [
          %Schedule{start_dt: ~U[2021-01-01T00:00:00Z], end_dt: ~U[2021-01-02T00:00:00Z]}
        ],
        now: ~U[2021-02-01T00:00:00Z]
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
    test "returns true with blank schedule", %{widget: widget} do
      assert WidgetInstance.valid_candidate?(widget)
    end

    test "returns false with old schedule", %{widget_old_schedule: widget_old_schedule} do
      refute WidgetInstance.valid_candidate?(widget_old_schedule)
    end
  end

  describe "audio_serialize/1" do
    test "returns empty string", %{widget: widget} do
      assert %{} == WidgetInstance.audio_serialize(widget)
    end
  end

  describe "audio_sort_key/1" do
    test "returns 0", %{widget: widget} do
      assert 0 == WidgetInstance.audio_sort_key(widget)
    end
  end

  describe "audio_valid_candidate?/1" do
    test "returns false", %{widget: widget} do
      refute WidgetInstance.audio_valid_candidate?(widget)
    end
  end

  describe "audio_view/1" do
    test "returns EvergreenContentView", %{widget: widget} do
      assert ScreensWeb.V2.Audio.EvergreenContentView == WidgetInstance.audio_view(widget)
    end
  end
end
