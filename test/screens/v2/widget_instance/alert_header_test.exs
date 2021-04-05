defmodule Screens.V2.WidgetInstance.AlertHeaderTest do
  use ExUnit.Case, async: true

  alias Screens.V2.WidgetInstance

  setup do
    %{
      instance_no_time: %WidgetInstance.AlertHeader{
        text: "Copley",
        icon: :logo,
        accent: :hatched,
        color: :green
      },
      instance_with_time: %WidgetInstance.AlertHeader{
        text: "Back Bay",
        icon: :logo,
        accent: :x,
        color: :orange,
        time: ~U[2021-03-04 11:00:00Z]
      }
    }
  end

  describe "priority/1" do
    test "returns 2", %{instance_no_time: instance} do
      assert [2] == WidgetInstance.priority(instance)
    end
  end

  describe "serialize/1" do
    test "handles header without time", %{instance_no_time: instance} do
      assert %{
               icon: :logo,
               text: "Copley",
               accent: :hatched,
               color: :green,
               time: nil
             } == WidgetInstance.serialize(instance)
    end

    test "handles header with time", %{instance_with_time: instance} do
      assert %{
               icon: :logo,
               text: "Back Bay",
               accent: :x,
               color: :orange,
               time: "2021-03-04T11:00:00Z"
             } == WidgetInstance.serialize(instance)
    end
  end

  describe "slot_names/1" do
    test "returns header", %{instance_no_time: instance} do
      assert [:header] == WidgetInstance.slot_names(instance)
    end
  end

  describe "widget_type/1" do
    test "returns alert_header", %{instance_no_time: instance} do
      assert :alert_header == WidgetInstance.widget_type(instance)
    end
  end
end
