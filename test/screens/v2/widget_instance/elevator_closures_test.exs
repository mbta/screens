defmodule Screens.V2.WidgetInstance.ElevatorClosuresTest do
  use ExUnit.Case, async: true

  alias Screens.V2.WidgetInstance
  alias Screens.V2.WidgetInstance.ElevatorClosures
  alias ScreensConfig.V2.Elevator

  setup do
    %{
      instance: %ElevatorClosures{
        app_params:
          struct(Elevator,
            elevator_id: "1",
            alternate_direction_text: "Test",
            accessible_path_direction_arrow: :n
          ),
        in_station_closures: [
          %ElevatorClosures.Closure{
            description: "Test Alert Description",
            elevator_name: "Test Elevator",
            elevator_id: "111",
            id: "1",
            header_text: "Test Alert Header"
          }
        ],
        other_stations_with_closures: [
          %ElevatorClosures.Station{
            name: "Forest Hills",
            route_icons: ["Orange"],
            closures: [
              %ElevatorClosures.Closure{
                description: "FH Alert Description",
                elevator_name: "FH Elevator",
                elevator_id: "222",
                id: "2",
                header_text: "FH Alert Header"
              }
            ]
          }
        ],
        now: ~U[2024-11-27T05:00:00Z]
      }
    }
  end

  describe "priority/1" do
    test "returns 0", %{instance: instance} do
      assert [0] == WidgetInstance.priority(instance)
    end
  end

  describe "serialize/1" do
    test "returns map with id and closures", %{instance: instance} do
      assert %{
               in_station_closures: instance.in_station_closures,
               other_stations_with_closures: instance.other_stations_with_closures,
               accessible_path_direction_arrow:
                 instance.app_params.accessible_path_direction_arrow,
               accessible_path_image_here_coordinates:
                 instance.app_params.accessible_path_image_here_coordinates,
               accessible_path_image_url: instance.app_params.accessible_path_image_url,
               alternate_direction_text: instance.app_params.alternate_direction_text,
               id: instance.app_params.elevator_id,
               time: "2024-11-27T05:00:00Z"
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
