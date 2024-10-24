defmodule Screens.V2.WidgetInstance.ElevatorClosuresTest do
  use ExUnit.Case, async: true

  alias Screens.V2.WidgetInstance
  alias Screens.V2.WidgetInstance.ElevatorClosures
  alias ScreensConfig.Screen
  alias ScreensConfig.V2.Elevator

  setup do
    %{
      instance: %ElevatorClosures{
        screen: struct(Screen, %{app_params: %Elevator{elevator_id: "111"}}),
        alerts: []
      }
    }
  end

  describe "priority/1" do
    test "returns 1", %{instance: instance} do
      assert [1] == WidgetInstance.priority(instance)
    end
  end

  describe "serialize/1" do
    test "returns map with id and alerts", %{instance: instance} do
      assert %{
               id: "111",
               in_station_alerts: [],
               outside_alerts: []
             } == WidgetInstance.serialize(instance)
    end
  end

  describe "slot_names/1" do
    test "returns main_content", %{instance: instance} do
      assert [:main_content] == WidgetInstance.slot_names(instance)
    end
  end

  describe "widget_type/1" do
    test "returns elevator_closures", %{instance: instance} do
      assert :elevator_closures == WidgetInstance.widget_type(instance)
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
      refute WidgetInstance.audio_valid_candidate?(instance)
    end
  end

  describe "audio_view/1" do
    test "returns ElevatorClosuresView", %{instance: instance} do
      assert ScreensWeb.V2.Audio.ElevatorClosuresView == WidgetInstance.audio_view(instance)
    end
  end
end
