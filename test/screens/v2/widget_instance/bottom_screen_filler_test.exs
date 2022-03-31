defmodule Screens.V2.WidgetInstance.BottomScreenFillerTest do
  use ExUnit.Case, async: true

  alias Screens.Config.Screen
  alias Screens.V2.WidgetInstance
  alias Screens.V2.WidgetInstance.BottomScreenFiller

  setup do
    %{
      instance: %BottomScreenFiller{screen: struct(Screen)}
    }
  end

  describe "priority/1" do
    test "returns low priority: [10]", %{instance: instance} do
      assert [10] == WidgetInstance.priority(instance)
    end
  end

  describe "serialize/1" do
    test "returns empty map", %{instance: instance} do
      assert %{} == WidgetInstance.serialize(instance)
    end
  end

  describe "slot_names/1" do
    test "returns [:full_body_bottom_screen]", %{instance: instance} do
      assert [:full_body_bottom_screen] == WidgetInstance.slot_names(instance)
    end
  end

  describe "widget_type/1" do
    test "returns :bottom_screen_filler", %{instance: instance} do
      assert :bottom_screen_filler == WidgetInstance.widget_type(instance)
    end
  end

  describe "valid_candidate?/1" do
    test "returns true", %{instance: instance} do
      assert true == WidgetInstance.valid_candidate?(instance)
    end
  end

  describe "audio_serialize/1" do
    test "returns empty map", %{instance: instance} do
      assert %{} == WidgetInstance.audio_serialize(instance)
    end
  end

  describe "audio_sort_key/1" do
    test "returns [0]", %{instance: instance} do
      assert [0] == WidgetInstance.audio_sort_key(instance)
    end
  end

  describe "audio_valid_candidate?/1" do
    test "returns false", %{instance: instance} do
      assert false == WidgetInstance.audio_valid_candidate?(instance)
    end
  end

  describe "audio_view/1" do
    test "returns ScreensWeb.V2.Audio.BottomScreenFillerView", %{instance: instance} do
      assert ScreensWeb.V2.Audio.BottomScreenFillerView == WidgetInstance.audio_view(instance)
    end
  end
end
