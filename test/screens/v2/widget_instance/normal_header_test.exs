defmodule Screens.V2.WidgetInstance.NormalHeaderTest do
  use ExUnit.Case, async: true

  alias Screens.V2.WidgetInstance

  setup do
    %{
      instance_one: %WidgetInstance.NormalHeader{
        icon: :logo,
        text: "Ruggles",
        time: ~U[2021-03-04 11:00:00Z]
      },
      instance_two: %WidgetInstance.NormalHeader{
        icon: :logo,
        text: "Ruggles",
        time: ~U[2021-03-04 11:00:00Z],
        slot_name: :header_right
      }
    }
  end

  describe "priority/1" do
    test "returns 2", %{instance_one: instance} do
      assert [2] == WidgetInstance.priority(instance)
    end
  end

  describe "serialize/1" do
    test "returns serialized text, icon and time", %{instance_one: instance} do
      assert %{
               icon: :logo,
               text: "Ruggles",
               time: "2021-03-04T11:00:00Z",
               show_to: false
             } == WidgetInstance.serialize(instance)
    end

    test "returns serialized text, icon, time, and slot_name", %{instance_two: instance} do
      assert %{
               icon: :logo,
               text: "Ruggles",
               time: "2021-03-04T11:00:00Z",
               show_to: false,
               slot_name: :header_right
             } == WidgetInstance.serialize(instance)
    end
  end

  describe "slot_names/1" do
    test "returns header", %{instance_one: instance} do
      assert [:header] == WidgetInstance.slot_names(instance)
    end

    test "returns header when slot_name was provided", %{instance_two: instance} do
      assert [:header_right] == WidgetInstance.slot_names(instance)
    end
  end

  describe "widget_type/1" do
    test "returns normal_header", %{instance_one: instance} do
      assert :normal_header == WidgetInstance.widget_type(instance)
    end
  end

  describe "audio_serialize/1" do
    test "returns map with text key", %{instance_one: instance} do
      assert %{text: _} = WidgetInstance.audio_serialize(instance)
    end
  end

  describe "audio_sort_key/1" do
    test "returns 0", %{instance_one: instance} do
      assert 0 == WidgetInstance.audio_sort_key(instance)
    end
  end

  describe "audio_valid_candidate?/1" do
    test "returns true", %{instance_one: instance} do
      assert WidgetInstance.audio_valid_candidate?(instance)
    end
  end

  describe "audio_view/1" do
    test "returns NormalHeaderView", %{instance_one: instance} do
      assert ScreensWeb.V2.Audio.NormalHeaderView == WidgetInstance.audio_view(instance)
    end
  end
end
