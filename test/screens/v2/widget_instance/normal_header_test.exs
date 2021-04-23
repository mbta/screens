defmodule Screens.V2.WidgetInstance.NormalHeaderTest do
  use ExUnit.Case, async: true

  alias Screens.V2.WidgetInstance

  setup do
    %{
      instance: %WidgetInstance.NormalHeader{
        icon: :logo,
        text: "Ruggles",
        time: ~U[2021-03-04 11:00:00Z]
      }
    }
  end

  describe "priority/1" do
    test "returns 2", %{instance: instance} do
      assert [2] == WidgetInstance.priority(instance)
    end
  end

  describe "serialize/1" do
    test "returns serialized text, icon and time", %{instance: instance} do
      assert %{
               icon: :logo,
               text: "Ruggles",
               time: "2021-03-04T11:00:00Z"
             } == WidgetInstance.serialize(instance)
    end
  end

  describe "slot_names/1" do
    test "returns header", %{instance: instance} do
      assert [:header] == WidgetInstance.slot_names(instance)
    end
  end

  describe "widget_type/1" do
    test "returns normal_header", %{instance: instance} do
      assert :normal_header == WidgetInstance.widget_type(instance)
    end
  end
end
