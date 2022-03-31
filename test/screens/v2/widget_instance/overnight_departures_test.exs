defmodule Screens.V2.WidgetInstance.OvernightDeparturesTest do
  use ExUnit.Case, async: true

  alias Screens.V2.WidgetInstance

  setup do
    %{
      instance: %WidgetInstance.OvernightDepartures{}
    }
  end

  describe "priority/1" do
    test "returns 1", %{instance: instance} do
      assert [1] == WidgetInstance.priority(instance)
    end
  end

  describe "serialize/1" do
    test "returns empty map", %{instance: instance} do
      assert %{} == WidgetInstance.serialize(instance)
    end
  end

  describe "slot_names/1" do
    test "returns full_screen", %{instance: instance} do
      assert [:full_screen] == WidgetInstance.slot_names(instance)
    end
  end

  describe "widget_type/1" do
    test "returns overnight_departures", %{instance: instance} do
      assert :overnight_departures == WidgetInstance.widget_type(instance)
    end
  end

  describe "audio_serialize/1" do
    test "returns empty map", %{instance: instance} do
      assert %{} = WidgetInstance.audio_serialize(instance)
    end
  end

  describe "audio_sort_key/1" do
    test "returns [0]", %{instance: instance} do
      assert [0] == WidgetInstance.audio_sort_key(instance)
    end
  end

  describe "audio_valid_candidate?/1" do
    test "returns false", %{instance: instance} do
      refute WidgetInstance.audio_valid_candidate?(instance)
    end
  end

  describe "audio_view/1" do
    test "returns OvernightDeparturesView", %{instance: instance} do
      assert ScreensWeb.V2.Audio.OvernightDeparturesView == WidgetInstance.audio_view(instance)
    end
  end
end
