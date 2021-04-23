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
end
