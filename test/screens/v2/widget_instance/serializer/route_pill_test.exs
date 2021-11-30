defmodule Screens.V2.WidgetInstance.Serializer.RoutePillTest do
  use ExUnit.Case, async: true

  import Screens.V2.WidgetInstance.Serializer.RoutePill

  describe "serialize_for_departure/4" do
    test "Uses track number if not nil" do
      assert %{type: :text, text: "TR3", color: :purple} ==
               serialize_for_departure("CR-Fairmount", "", :rail, 3)
    end

    test "Returns rail icon if route type is :rail" do
      assert %{type: :icon, icon: :rail, color: :purple} ==
               serialize_for_departure("CR-Fairmount", "", :rail, nil)
    end

    test "Returns boat icon if route type is :ferry" do
      assert %{type: :icon, icon: :boat, color: :teal} ==
               serialize_for_departure("Boat-F1", "", :ferry, nil)
    end

    test "Returns slashed route pill if route name contains `/`" do
      assert %{type: :slashed, part1: "34", part2: "35", color: :yellow} ==
               serialize_for_departure("3435", "34/35", :bus, nil)
    end

    test "Returns RL for Red Line" do
      assert %{type: :text, text: "RL", color: :red} ==
               serialize_for_departure("Red", "", :subway, nil)
    end

    test "Does not include branch name for Green Line" do
      assert %{type: :text, text: "GL", color: :green} ==
               serialize_for_departure("Green-B", "", :light_rail, nil)
    end

    test "Handles Silver Line routes" do
      assert %{type: :text, text: "SL1", color: :silver} ==
               serialize_for_departure("741", "", :bus, nil)
    end

    test "Handles cross-town routes" do
      assert %{type: :text, text: "CT2", color: :yellow} ==
               serialize_for_departure("747", "", :bus, nil)
    end

    test "Uses route ID for normal bus routes" do
      assert %{type: :text, text: "44", color: :yellow} ==
               serialize_for_departure("44", "", :bus, nil)
    end

    test "Uses route name for non-special case routes if not empty" do
      assert %{type: :text, text: "NewRoute999", color: :yellow} ==
               serialize_for_departure("999", "NewRoute999", :bus, nil)
    end
  end

  describe "serialize_route_for_alert/1" do
    test "Returns RL for Red Line" do
      assert %{type: :text, text: "RL", color: :red} == serialize_route_for_alert("Red")
    end

    test "Includes branch name and long text for Green Line" do
      assert %{type: :text, text: "Green Line B", color: :green} ==
               serialize_route_for_alert("Green-B")
    end

    test "Abbreviates Commuter Rail route names" do
      assert %{type: :text, text: "LWL", color: :purple} == serialize_route_for_alert("CR-Lowell")
    end

    test "Returns boat icon for ferry routes" do
      assert %{type: :icon, icon: :boat, color: :teal} == serialize_route_for_alert("Boat-F4")
    end

    test "Handles Silver Line routes" do
      assert %{type: :text, text: "SL1", color: :silver} == serialize_route_for_alert("741")
    end

    test "Handles cross-town routes" do
      assert %{type: :text, text: "CT2", color: :yellow} == serialize_route_for_alert("747")
    end

    test "Uses route ID for normal bus routes" do
      assert %{type: :text, text: "44", color: :yellow} == serialize_route_for_alert("44")
    end
  end
end
