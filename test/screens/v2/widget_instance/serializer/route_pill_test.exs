defmodule Screens.V2.WidgetInstance.Serializer.RoutePillTest do
  use ExUnit.Case, async: true

  alias ScreensConfig.Screen

  import ExUnit.CaptureLog
  import Screens.TestSupport.RouteBuilder
  import Screens.V2.WidgetInstance.Serializer.RoutePill

  describe "serialize_for_departure/3" do
    setup do
      pre_fare_screen = struct(Screen, %{app_id: :pre_fare_v2})
      gl_eink_screen = struct(Screen, %{app_id: :gl_eink_v2})

      %{
        gl_eink_screen: gl_eink_screen,
        pre_fare_screen: pre_fare_screen
      }
    end

    test "Returns rail icon with a route abbreviation for Commuter Rail", %{
      pre_fare_screen: screen
    } do
      assert %{type: :icon, icon: :rail, color: :purple, route_abbrev: "FMT"} ==
               serialize_for_departure(route(id: "CR-Fairmount", type: :rail), nil, screen)
    end

    test "Returns track number with route abbreviation for CR when not nil", %{
      pre_fare_screen: screen
    } do
      assert %{type: :text, text: "TR3", color: :purple, route_abbrev: "FMT"} ==
               serialize_for_departure(route(id: "CR-Fairmount", type: :rail), 3, screen)
    end

    test "Returns no abbreviation and logs a warning for an unknown CR route", %{
      pre_fare_screen: screen
    } do
      logs =
        capture_log([level: :warning], fn ->
          assert %{type: :icon, icon: :rail, color: :purple, route_abbrev: nil} ==
                   serialize_for_departure(route(id: "CR-Foobar", type: :rail), nil, screen)
        end)

      assert logs =~ ~s(missing_route_pill_abbreviation line=Foobar)
    end

    test "Returns boat icon if route type is :ferry", %{pre_fare_screen: screen} do
      assert %{type: :icon, icon: :boat, color: :teal} ==
               serialize_for_departure(route(id: "Boat-F1", type: :ferry), nil, screen)
    end

    test "Returns ocean blue rail icon for CapeFlyer", %{pre_fare_screen: screen} do
      assert %{type: :icon, icon: :rail, color: :ocean_blue} ==
               serialize_for_departure(route(id: "CapeFlyer", type: :rail), nil, screen)
    end

    test "Returns slashed route pill if route name contains `/`", %{pre_fare_screen: screen} do
      assert %{type: :slashed, part1: "34", part2: "35", color: :yellow} ==
               serialize_for_departure(route(id: "3435", type: :bus, name: "34/35"), nil, screen)
    end

    test "Returns RL for Red Line", %{pre_fare_screen: screen} do
      assert %{type: :text, text: "RL", color: :red} ==
               serialize_for_departure(route(id: "Red", type: :subway), nil, screen)
    end

    test "Does not include branch name for Green Line", %{pre_fare_screen: screen} do
      assert %{type: :text, text: "GL", color: :green} ==
               serialize_for_departure(route(id: "Green", type: :light_rail), nil, screen)
    end

    test "Includes branch name for Green Line", %{
      pre_fare_screen: screen
    } do
      assert %{type: :text, text: "GL·B", color: :green} ==
               serialize_for_departure(route(id: "Green-B", type: :light_rail), nil, screen)
    end

    test "Handles Silver Line routes", %{pre_fare_screen: screen} do
      assert %{type: :text, text: "SL1", color: :silver} ==
               serialize_for_departure(route(id: "741", type: :bus), nil, screen)
    end

    test "Handles cross-town routes", %{pre_fare_screen: screen} do
      assert %{type: :text, text: "CT2", color: :yellow} ==
               serialize_for_departure(
                 route(
                   id: "747",
                   type: :bus,
                   name: "",
                   line_id: "line-747"
                 ),
                 nil,
                 screen
               )
    end

    test "Uses route ID for normal bus routes", %{pre_fare_screen: screen} do
      assert %{type: :text, text: "44", color: :yellow} ==
               serialize_for_departure(
                 route(
                   id: "44",
                   type: :bus,
                   name: "",
                   line_id: "line-44"
                 ),
                 nil,
                 screen
               )
    end

    test "Uses route ID for non-special case routes if route name is too long", %{
      pre_fare_screen: screen
    } do
      assert %{type: :text, text: "999", color: :yellow} ==
               serialize_for_departure(
                 route(
                   id: "999",
                   type: :bus,
                   name: "NewRoute999",
                   line_id: "line-999"
                 ),
                 nil,
                 screen
               )
    end

    test "Uses route name for non-special case routes if route ID is too long", %{
      pre_fare_screen: screen
    } do
      assert %{type: :text, text: "SHU", color: :yellow} ==
               serialize_for_departure(
                 route(id: "Example Long ID", type: :bus, name: "SHU"),
                 nil,
                 screen
               )
    end

    test "Returns icon if both route ID and name are too long", %{pre_fare_screen: screen} do
      assert %{type: :icon, icon: :bus, color: :yellow} ==
               serialize_for_departure(
                 route(id: "Example Long ID", type: :bus, name: "Example Long Name"),
                 nil,
                 screen
               )
    end

    test "Returns dual pill for Red Line shuttle", %{pre_fare_screen: screen} do
      route =
        route(
          id: "Shuttle-BoylstonKenmore (shuttle)",
          type: :bus,
          line_id: "line-Red"
        )

      assert %{type: :dual, text: "RL", icon: :bus, color: :red, secondary_color: :yellow} ==
               serialize_for_departure(route, nil, screen)
    end

    test "Returns dual pill for Blue Line shuttle", %{pre_fare_screen: screen} do
      route =
        route(
          id: "Blue Line Shuttle (shuttle)",
          type: :bus,
          line_id: "line-Blue"
        )

      assert %{type: :dual, text: "BL", icon: :bus, color: :blue, secondary_color: :yellow} ==
               serialize_for_departure(route, nil, screen)
    end

    test "Returns dual pill for Orange Line shuttle", %{pre_fare_screen: screen} do
      route =
        route(
          id: "Orange Line Shuttle (shuttle)",
          type: :bus,
          line_id: "line-Orange"
        )

      assert %{type: :dual, text: "OL", icon: :bus, color: :orange, secondary_color: :yellow} ==
               serialize_for_departure(route, nil, screen)
    end

    test "Returns dual pill for Commuter Rail shuttle", %{pre_fare_screen: screen} do
      route =
        route(
          id: "CR-Lowell Shuttle (shuttle)",
          type: :bus,
          line_id: "line-CR-Lowell"
        )

      assert %{type: :dual, text: "CR", icon: :bus, color: :purple, secondary_color: :yellow} ==
               serialize_for_departure(route, nil, screen)
    end

    test "Does not return dual pill for Green Line shuttle", %{pre_fare_screen: screen} do
      route =
        route(
          id: "GL Shuttle (shuttle)",
          type: :bus,
          line_id: "line-Green"
        )

      assert %{type: :icon, icon: :bus, color: :yellow} ==
               serialize_for_departure(route, nil, screen)
    end

    test "Does not return dual pill for Mattapan Line shuttle", %{pre_fare_screen: screen} do
      route =
        route(
          id: "Mattapan Shuttle (shuttle)",
          type: :bus,
          line_id: "line-Mattapan"
        )

      assert %{type: :icon, icon: :bus, color: :yellow} ==
               serialize_for_departure(route, nil, screen)
    end

    test "Does not return dual pill on eink screen", %{gl_eink_screen: screen} do
      route =
        route(
          id: "Blue Line Shuttle (shuttle)",
          type: :bus,
          line_id: "line-Blue"
        )

      assert %{type: :icon, icon: :bus, color: :yellow} ==
               serialize_for_departure(route, nil, screen)
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
