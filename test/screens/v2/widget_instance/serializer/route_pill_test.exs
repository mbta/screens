defmodule Screens.V2.WidgetInstance.Serializer.RoutePillTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog
  import Screens.V2.WidgetInstance.Serializer.RoutePill

  describe "serialize_for_departure/4" do
    test "Returns rail icon with a route abbreviation for Commuter Rail" do
      assert %{type: :icon, icon: :rail, color: :purple, route_abbrev: "FMT"} ==
               serialize_for_departure("CR-Fairmount", "", :rail, nil)
    end

    test "Returns track number with route abbreviation for CR when not nil" do
      assert %{type: :text, text: "TR3", color: :purple, route_abbrev: "FMT"} ==
               serialize_for_departure("CR-Fairmount", "", :rail, 3)
    end

    test "Returns no abbreviation and logs a warning for an unknown CR route" do
      logs =
        capture_log([level: :warning], fn ->
          assert %{type: :icon, icon: :rail, color: :purple, route_abbrev: nil} ==
                   serialize_for_departure("CR-Foobar", "", :rail, nil)
        end)

      assert logs =~ "missing route pill abbreviation for CR-Foobar"
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
               serialize_for_departure("Green", "", :light_rail, nil)
    end

    test "Includes branch name for Green Line" do
      assert %{type: :text, text: "GL·B", color: :green} ==
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

    test "Includes a text abbreviation for Commuter Rail routes" do
      assert %{type: :icon, icon: :rail, color: :purple, route_abbrev: "LWL"} ==
               serialize_route_for_alert("CR-Lowell")
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

  describe "serialize_route_for_alert/2" do
    test "Includes branch name and short text for Green Line" do
      assert %{type: :text, text: "GL·B", color: :green} ==
               serialize_route_for_alert("Green-B", false)
    end
  end

  describe "serialize_route_for_reconstructed_alert/1" do
    test "Returns RL for Red Line" do
      assert %{type: :text, text: "RL", color: :red} ==
               serialize_route_for_reconstructed_alert({"Red", []})
    end

    test "Returns RED LINE for large Red Line" do
      assert %{type: :text, text: "RED LINE", color: :red} ==
               serialize_route_for_reconstructed_alert({"Red", []}, %{large: true})
    end

    test "Includes branch list and text for Green Line" do
      assert %{type: :text, text: "GL", color: :green, branches: ["B"]} ==
               serialize_route_for_reconstructed_alert({"Green", ["Green-B"]})
    end
  end
end
