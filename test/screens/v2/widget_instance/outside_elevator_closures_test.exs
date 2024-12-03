defmodule Screens.V2.WidgetInstance.OutsideElevatorClosuresTest do
  use ExUnit.Case, async: true

  alias Screens.V2.WidgetInstance
  alias Screens.V2.WidgetInstance.Elevator.Closure
  alias Screens.V2.WidgetInstance.OutsideElevatorClosures
  alias ScreensConfig.V2.Elevator

  setup do
    %{
      instance: %OutsideElevatorClosures{
        app_params:
          struct(Elevator,
            elevator_id: "1",
            alternate_direction_text: "Test",
            accessible_path_direction_arrow: :n
          ),
        in_station_closures: [
          %Closure{
            description: "Test Alert Description",
            elevator_name: "Test Elevator",
            elevator_id: "111",
            id: "1",
            header_text: "Test Alert Header"
          }
        ],
        other_stations_with_closures: [
          %OutsideElevatorClosures.Station{
            name: "Forest Hills",
            route_icons: ["Orange"],
            closures: [
              %Closure{
                description: "FH Alert Description",
                elevator_name: "FH Elevator",
                elevator_id: "222",
                id: "2",
                header_text: "FH Alert Header"
              }
            ]
          }
        ]
      }
    }
  end

  describe "priority/1" do
    test "returns 1", %{instance: instance} do
      assert [1] == WidgetInstance.priority(instance)
    end
  end

  describe "serialize/1" do
    test "returns map with id and closures", %{instance: instance} do
      assert %{
               in_station_closures: instance.in_station_closures,
               other_stations_with_closures: instance.other_stations_with_closures,
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
    test "returns outside_elevator_closures", %{instance: instance} do
      assert :outside_elevator_closures == WidgetInstance.widget_type(instance)
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
    test "returns OutsideElevatorClosuresView", %{instance: instance} do
      assert ScreensWeb.V2.Audio.OutsideElevatorClosuresView ==
               WidgetInstance.audio_view(instance)
    end
  end
end
