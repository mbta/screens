defmodule Screens.V2.WidgetInstance.DeparturesNoSerivceTest do
  use ExUnit.Case, async: true
  alias Screens.V2.WidgetInstance
  alias Screens.Config.Screen
  alias Screens.Config.V2.BusEink

  setup do
    %{
      widget: %WidgetInstance.DeparturesNoService{
        screen: struct(Screen, %{app_params: struct(BusEink)})
      }
    }
  end

  describe "priority/1" do
    test "returns 2", %{widget: widget} do
      assert [2] == WidgetInstance.priority(widget)
    end
  end

  describe "serialize/1" do
    test "returns empty map", %{widget: widget} do
      assert %{} == WidgetInstance.serialize(widget)
    end
  end

  describe "slot_names/1" do
    test "returns main_content", %{widget: widget} do
      assert [:main_content] == WidgetInstance.slot_names(widget)
    end
  end

  describe "widget_type/1" do
    test "returns departures no service", %{widget: widget} do
      assert :departures_no_service == WidgetInstance.widget_type(widget)
    end
  end

  describe "audio_serialize/1" do
    test "returns empty string", %{widget: widget} do
      assert %{} == WidgetInstance.audio_serialize(widget)
    end
  end

  describe "audio_sort_key/1" do
    test "returns [0]", %{widget: widget} do
      assert [0] == WidgetInstance.audio_sort_key(widget)
    end
  end

  describe "audio_valid_candidate?/1" do
    test "returns false", %{widget: widget} do
      refute WidgetInstance.audio_valid_candidate?(widget)
    end
  end

  describe "audio_view/1" do
    test "returns DeparturesNoServiceView", %{widget: widget} do
      assert ScreensWeb.V2.Audio.DeparturesNoServiceView ==
               WidgetInstance.audio_view(widget)
    end
  end
end
