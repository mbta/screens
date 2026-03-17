defmodule Screens.V2.WidgetInstance.WayfindingTest do
  use ExUnit.Case, async: true

  alias Screens.V2.WidgetInstance
  alias Screens.V2.WidgetInstance.Wayfinding
  alias ScreensConfig.Screen

  setup do
    %{
      widget: %Wayfinding{
        screen: %Screen{app_params: nil, vendor: nil, device_id: nil, name: nil, app_id: nil},
        asset_url: "test_url",
        header_text: "test_header_text",
        text_for_audio: "test_text_for_audio",
        slot_names: [:main_content_left]
      }
    }
  end

  describe "priority/1" do
    test "returns priority", %{widget: widget} do
      assert [3] == WidgetInstance.priority(widget)
    end
  end

  describe "serialize/1" do
    test "returns asset_url and header_text", %{widget: widget} do
      assert %{asset_url: "test_url", header_text: "test_header_text"} ==
               WidgetInstance.serialize(widget)
    end
  end

  describe "widget_type/1" do
    test "returns :wayfinding", %{widget: widget} do
      assert :wayfinding == WidgetInstance.widget_type(widget)
    end
  end

  describe "valid_candidate?/1" do
    test "returns based on asset_url", %{widget: widget} do
      assert WidgetInstance.valid_candidate?(widget)

      no_asset_url_widget = %Wayfinding{
        screen: %Screen{app_params: nil, vendor: nil, device_id: nil, name: nil, app_id: nil},
        asset_url: nil,
        header_text: "test_header_text",
        text_for_audio: "test_text_for_audio",
        slot_names: [:main_content_left]
      }

      refute WidgetInstance.valid_candidate?(no_asset_url_widget)
    end
  end

  describe "audio_serialize/1" do
    test "returns text_for_audio", %{widget: widget} do
      assert %{text: "test_text_for_audio"} == WidgetInstance.audio_serialize(widget)
    end
  end

  describe "audio_sort_key/1" do
    test "returns [2]", %{widget: widget} do
      assert [2] == WidgetInstance.audio_sort_key(widget)
    end
  end

  describe "audio_valid_candidate?/1" do
    test "returns true if text_for_audio exists", %{widget: widget} do
      assert WidgetInstance.audio_valid_candidate?(widget)
    end

    test "returns false if text_for_audio is nil" do
      no_text_for_audio_widget = %Wayfinding{
        screen: %Screen{app_params: nil, vendor: nil, device_id: nil, name: nil, app_id: nil},
        asset_url: "test_url",
        header_text: "test_header_text",
        text_for_audio: nil,
        slot_names: [:main_content_left]
      }

      refute WidgetInstance.audio_valid_candidate?(no_text_for_audio_widget)
    end
  end
end
