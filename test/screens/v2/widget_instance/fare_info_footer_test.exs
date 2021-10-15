defmodule Screens.V2.WidgetInstance.FareInfoFooterTest do
  use ExUnit.Case, async: true

  alias Screens.V2.WidgetInstance

  setup do
    %{
      bus_instance: %WidgetInstance.FareInfoFooter{
        mode: :bus,
        text: "More at",
        url: "mbta.com/stops/1722"
      },
      subway_instance: %WidgetInstance.FareInfoFooter{
        mode: :subway,
        text: "For real-time predictions and fare purchase locations:",
        url: "mbta.com/stops/place-bland"
      }
    }
  end

  describe "priority/1" do
    test "returns 2", %{bus_instance: instance} do
      assert [2] == WidgetInstance.priority(instance)
    end
  end

  describe "serialize/1" do
    test "returns correct result for bus", %{bus_instance: instance} do
      assert %{
               mode_icon: "bus-negative-black.svg",
               mode_text: "Local Bus",
               mode_cost: "$1.70",
               text: "More at",
               url: "mbta.com/stops/1722"
             } == WidgetInstance.serialize(instance)
    end

    test "returns correct result for subway", %{subway_instance: instance} do
      assert %{
               mode_icon: "subway-negative-black.svg",
               mode_text: "Subway",
               mode_cost: "$2.40",
               text: "For real-time predictions and fare purchase locations:",
               url: "mbta.com/stops/place-bland"
             } == WidgetInstance.serialize(instance)
    end
  end

  describe "slot_names/1" do
    test "returns footer", %{bus_instance: instance} do
      assert [:footer] == WidgetInstance.slot_names(instance)
    end
  end

  describe "widget_type/1" do
    test "returns fare_info_footer", %{bus_instance: instance} do
      assert :fare_info_footer == WidgetInstance.widget_type(instance)
    end
  end

  describe "audio_serialize/1" do
    test "returns empty string for bus", %{bus_instance: instance} do
      assert %{} == WidgetInstance.audio_serialize(instance)
    end

    test "returns empty string for subway", %{subway_instance: instance} do
      assert %{} == WidgetInstance.audio_serialize(instance)
    end
  end

  describe "audio_sort_key/1" do
    test "returns 0 for bus", %{bus_instance: instance} do
      assert 0 == WidgetInstance.audio_sort_key(instance)
    end

    test "returns 0 for subway", %{subway_instance: instance} do
      assert 0 == WidgetInstance.audio_sort_key(instance)
    end
  end

  describe "audio_valid_candidate?/1" do
    test "returns false for bus", %{bus_instance: instance} do
      refute WidgetInstance.audio_valid_candidate?(instance)
    end

    test "returns false for subway", %{subway_instance: instance} do
      refute WidgetInstance.audio_valid_candidate?(instance)
    end
  end

  describe "audio_view/1" do
    test "returns FareInfoFooterView for bus", %{bus_instance: instance} do
      assert ScreensWeb.V2.Audio.FareInfoFooterView == WidgetInstance.audio_view(instance)
    end

    test "returns FareInfoFooterView for subway", %{subway_instance: instance} do
      assert ScreensWeb.V2.Audio.FareInfoFooterView == WidgetInstance.audio_view(instance)
    end
  end
end
