defmodule Screens.V2.WidgetInstance.DeparturesNoDataTest do
  use ExUnit.Case, async: true
  alias Screens.V2.WidgetInstance

  @instance %WidgetInstance.DeparturesNoData{}

  describe "priority/1" do
    test "returns 2" do
      assert [2] == WidgetInstance.priority(@instance)
    end
  end

  describe "serialize/1" do
    test "returns empty map" do
      assert %{} == WidgetInstance.serialize(@instance)
    end
  end

  describe "slot_names/1" do
    test "returns main_content" do
      assert [:main_content] == WidgetInstance.slot_names(@instance)
    end
  end

  describe "widget_type/1" do
    test "returns departures no data" do
      assert :departures_no_data == WidgetInstance.widget_type(@instance)
    end
  end
end
