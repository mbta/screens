defmodule Screens.V2.WidgetInstance.NormalFooterTest do
  use ExUnit.Case, async: true

  alias Screens.V2.WidgetInstance

  setup do
    %{
      instance: %WidgetInstance.NormalFooter{
        url: "mbta.com/stops/1722"
      }
    }
  end

  describe "priority/1" do
    test "returns 2", %{instance: instance} do
      assert [2] == WidgetInstance.priority(instance)
    end
  end

  describe "serialize/1" do
    test "returns serialized url", %{instance: instance} do
      assert %{
               url: "mbta.com/stops/1722"
             } == WidgetInstance.serialize(instance)
    end
  end

  describe "slot_names/1" do
    test "returns footer", %{instance: instance} do
      assert [:footer] == WidgetInstance.slot_names(instance)
    end
  end

  describe "widget_type/1" do
    test "returns normal_footer", %{instance: instance} do
      assert :normal_footer == WidgetInstance.widget_type(instance)
    end
  end
end
