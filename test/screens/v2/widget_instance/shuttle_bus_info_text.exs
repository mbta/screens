defmodule Screens.V2.WidgetInstance.ShuttleBusInfoTest do
  use ExUnit.Case, async: true

  alias Screens.V2.WidgetInstance
  alias Screens.Config.Screen
  alias Screens.V2.WidgetInstance.ShuttleBusInfo
  alias Screens.Config.V2.Schedule

  setup do
    %{
      widget: %ShuttleBusInfo{
        screen: %Screen{
          app_params: nil,
          vendor: nil,
          device_id: nil,
          name: nil,
          app_id: :pre_fare_v2
        },
        slot_names: [:large],
        eta: "35-45",
        destination: "Test Station",
        direction: "north",
        priority: [2, 3, 1]
      },
      widget_not_pre_fare: %ShuttleBusInfo{
        screen: %Screen{
          app_params: nil,
          vendor: nil,
          device_id: nil,
          name: nil,
          app_id: :bus_shelter_v2
        }
      }
    }
  end

  describe "priority/1" do
    test "returns priority defined on the struct", %{widget: widget} do
      assert [2, 3, 1] == WidgetInstance.priority(widget)
    end
  end

  describe "serialize/1" do
    test "returns map with eta, destination, and direction", %{widget: widget} do
      assert %{
               eta: "35-45",
               destination: "Test Station",
               direction: "north"
             } == WidgetInstance.serialize(widget)
    end
  end

  describe "slot_names/1" do
    test "returns slot names defined on the struct", %{widget: widget} do
      assert [:large] == WidgetInstance.slot_names(widget)
    end
  end

  describe "widget_type/1" do
    test "returns :shuttle_bus_info", %{widget: widget} do
      assert :shuttle_bus_info == WidgetInstance.widget_type(widget)
    end
  end

  describe "valid_candidate?/1" do
    test "returns true for pre-fare", %{widget: widget} do
      assert WidgetInstance.valid_candidate?(widget)
    end

    test "returns false with old schedule", %{widget_not_pre_fare: widget_not_pre_fare} do
      refute WidgetInstance.valid_candidate?(widget_not_pre_fare)
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
    test "returns ShuttleBusInfoView", %{widget: widget} do
      assert ScreensWeb.V2.Audio.ShuttleBusInfoView == WidgetInstance.audio_view(widget)
    end
  end
end
