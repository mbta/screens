defmodule Screens.V2.WidgetInstance.CurrentElevatorClosedTest do
  use ExUnit.Case, async: true

  alias Screens.V2.WidgetInstance
  alias Screens.V2.WidgetInstance.CurrentElevatorClosed
  alias ScreensConfig.V2.Elevator

  setup do
    %{
      instance: %CurrentElevatorClosed{
        app_params:
          struct(Elevator,
            elevator_id: "111",
            alternate_direction_text: "Test",
            accessible_path_direction_arrow: :n
          ),
        closure: %CurrentElevatorClosed.Closure{
          description: "Test Alert Description",
          elevator_name: "Test Elevator",
          elevator_id: "111",
          id: "1",
          header_text: "Test Alert Header"
        }
      }
    }
  end

  describe "priority/1" do
    test "returns 1", %{instance: instance} do
      assert [1] == WidgetInstance.priority(instance)
    end
  end

  describe "serialize/1" do
    test "returns map with id, closure, and alternate direction info", %{instance: instance} do
      assert %{
               closure: instance.closure,
               accessible_path_direction_arrow:
                 instance.app_params.accessible_path_direction_arrow,
               accessible_path_image_here_coordinates:
                 instance.app_params.accessible_path_image_here_coordinates,
               accessible_path_image_url: instance.app_params.accessible_path_image_url,
               alternate_direction_text: instance.app_params.alternate_direction_text,
               id: instance.app_params.elevator_id
             } == WidgetInstance.serialize(instance)
    end
  end

  describe "slot_names/1" do
    test "returns main_content", %{instance: instance} do
      assert [:main_content] == WidgetInstance.slot_names(instance)
    end
  end

  describe "widget_type/1" do
    test "returns current_elevator_closed", %{instance: instance} do
      assert :current_elevator_closed == WidgetInstance.widget_type(instance)
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
    test "returns CurrentElevatorClosedView", %{instance: instance} do
      assert ScreensWeb.V2.Audio.CurrentElevatorClosedView == WidgetInstance.audio_view(instance)
    end
  end
end
