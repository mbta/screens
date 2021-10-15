defmodule Screens.V2.WidgetInstance.LinkFooterTest do
  use ExUnit.Case, async: true

  alias Screens.V2.WidgetInstance

  setup do
    %{
      instance: %WidgetInstance.LinkFooter{
        text: "For real-time predictions and fare purchase locations:",
        url: "mbta.com/stops/1722"
      }
    }
  end

  describe "priority/1" do
    test "returns 2", %{instance: instance} do
      assert [2] == WidgetInstance.priority(instance)
    end
  end

  describe "serialize/1" do
    test "returns serialized text and url", %{instance: instance} do
      assert %{
               text: "For real-time predictions and fare purchase locations:",
               url: "mbta.com/stops/1722"
             } == WidgetInstance.serialize(instance)
    end
  end

  describe "slot_names/1" do
    test "returns footer", %{instance: instance} do
      assert [:footer] == WidgetInstance.slot_names(instance)
    end
  end

  describe "widget_type/1" do
    test "returns link_footer", %{instance: instance} do
      assert :link_footer == WidgetInstance.widget_type(instance)
    end
  end

  describe "audio_serialize/1" do
    test "returns empty string", %{instance: instance} do
      assert %{} == WidgetInstance.audio_serialize(instance)
    end
  end

  describe "audio_sort_key/1" do
    test "returns 0", %{instance: instance} do
      assert 0 == WidgetInstance.audio_sort_key(instance)
    end
  end

  describe "audio_valid_candidate?/1" do
    test "returns false", %{instance: instance} do
      refute WidgetInstance.audio_valid_candidate?(instance)
    end
  end

  describe "audio_view/1" do
    test "returns LinkFooterView", %{instance: instance} do
      assert ScreensWeb.V2.Audio.LinkFooterView == WidgetInstance.audio_view(instance)
    end
  end
end
