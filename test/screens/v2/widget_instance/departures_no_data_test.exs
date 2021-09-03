defmodule Screens.V2.WidgetInstance.DeparturesNoDataTest do
  use ExUnit.Case, async: true
  alias Screens.V2.WidgetInstance
  alias Screens.Config.Screen
  alias Screens.Config.V2.BusShelter
  alias Screens.Config.V2.Header.CurrentStopId

  @instance %WidgetInstance.DeparturesNoData{
    screen:
      struct(Screen, %{app_params: struct(BusShelter, %{header: %CurrentStopId{stop_id: "1"}})}),
    show_alternatives?: true
  }

  describe "priority/1" do
    test "returns 2" do
      assert [2] == WidgetInstance.priority(@instance)
    end
  end

  describe "serialize/1" do
    test "returns stop ID and `show_alternatives?`" do
      assert %{stop_id: "1", show_alternatives: true} == WidgetInstance.serialize(@instance)
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
