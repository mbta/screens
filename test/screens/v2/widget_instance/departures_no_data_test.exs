defmodule Screens.V2.WidgetInstance.DeparturesNoDataTest do
  use ExUnit.Case, async: true
  alias Screens.V2.WidgetInstance
  alias Screens.Config.Screen
  alias Screens.Config.V2.BusShelter
  alias Screens.Config.V2.Header.CurrentStopId

  @instance %WidgetInstance.DeparturesNoData{
    screen:
      struct(Screen, %{app_params: struct(BusShelter, %{header: %CurrentStopId{stop_id: "1"}})}),
    show_alternatives?: true
  }

  describe "priority/1" do
    test "returns 2" do
      assert [2] == WidgetInstance.priority(@instance)
    end
  end

  describe "serialize/1" do
    test "returns stop ID and `show_alternatives?`" do
      assert %{stop_id: "1", show_alternatives: true} == WidgetInstance.serialize(@instance)
    end
  end

  describe "slot_names/1" do
    test "returns main_content" do
      assert [:main_content] == WidgetInstance.slot_names(@instance)
    end
  end

  describe "widget_type/1" do
    test "returns departures no data" do
      assert :departures_no_data == WidgetInstance.widget_type(@instance)
    end
  end

  describe "audio_serialize/1" do
    test "returns empty string" do
      assert %{} == WidgetInstance.audio_serialize(@instance)
    end
  end

  describe "audio_sort_key/1" do
    test "returns [0]" do
      assert [0] == WidgetInstance.audio_sort_key(@instance)
    end
  end

  describe "audio_valid_candidate?/1" do
    test "returns false" do
      refute WidgetInstance.audio_valid_candidate?(@instance)
    end
  end

  describe "audio_view/1" do
    test "returns DeparturesNoDataView" do
      assert ScreensWeb.V2.Audio.DeparturesNoDataView ==
               WidgetInstance.audio_view(@instance)
    end
  end
end
