defmodule Screens.V2.WidgetInstance.SurveyTest do
  use ExUnit.Case, async: true

  alias Screens.V2.WidgetInstance
  alias Screens.Config.Screen
  alias Screens.V2.WidgetInstance.Survey

  setup do
    %{
      widget: %Survey{
        screen: %Screen{app_params: nil, vendor: nil, device_id: nil, name: nil, app_id: nil},
        enabled?: false,
        medium_asset_url: "medium.png",
        large_asset_url: "large.png"
      }
    }
  end

  defp put_app_id(widget, app_id) do
    %{widget | screen: %{widget.screen | app_id: app_id}}
  end

  defp put_enabled(widget, enabled?) do
    %{widget | enabled?: enabled?}
  end

  describe "priority/1" do
    test "returns low flex zone priority", %{widget: widget} do
      assert [2, 10] == WidgetInstance.priority(widget)
    end
  end

  describe "serialize/1" do
    test "returns asset urls in a map", %{widget: widget} do
      assert %{medium_asset_url: "medium.png", large_asset_url: "large.png"} ==
               WidgetInstance.serialize(widget)
    end
  end

  describe "slot_names/1" do
    test "returns large and medium for bus shelter", %{widget: widget} do
      widget = put_app_id(widget, :bus_shelter_v2)

      assert [:large, :medium_left, :medium_right] == WidgetInstance.slot_names(widget)
    end

    test "not defined for non-bus shelter apps", %{widget: widget} do
      widget = put_app_id(widget, :gl_eink_v2)

      assert_raise FunctionClauseError, fn -> WidgetInstance.slot_names(widget) end
    end
  end

  describe "widget_type/1" do
    test "returns :survey", %{widget: widget} do
      assert :survey == WidgetInstance.widget_type(widget)
    end
  end

  describe "valid_candidate?/1" do
    test "returns value of `enabled?` field", %{widget: widget} do
      widget = put_enabled(widget, true)
      assert WidgetInstance.valid_candidate?(widget)

      widget = put_enabled(widget, false)
      refute WidgetInstance.valid_candidate?(widget)
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
    test "returns SurveyView", %{widget: widget} do
      assert ScreensWeb.V2.Audio.SurveyView == WidgetInstance.audio_view(widget)
    end
  end
end
