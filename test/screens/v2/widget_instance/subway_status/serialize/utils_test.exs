defmodule Screens.V2.WidgetInstance.SubwayStatus.Serialize.UtilsTest do
  use ExUnit.Case

  alias Screens.Routes.Route

  import Screens.V2.WidgetInstance.SubwayStatus.Serialize.Utils
  import Screens.TestSupport.InformedEntityBuilder

  describe "get_location/2" do
    test "returns 'entire line' for a whole route alert" do
      ie = ie(route: %Route{id: "Blue", direction_names: ["West", "East"]})

      assert "Entire line" = get_location([ie], "Blue")
    end

    test "returns 'Entire Mattapan line' for a whole route alert on Mattapan" do
      ie = ie(route: %Route{id: "Mattapan", direction_names: ["West", "East"]})

      assert "Entire Mattapan line" = get_location([ie], "Mattapan")
    end

    test "returns a direction for a whole direction alert" do
      ie = ie(route: %Route{id: "Blue", direction_names: ["West", "East"]}, direction_id: 0)

      assert %{full: "Westbound", abbrev: "Westbound"} = get_location([ie], "Blue")
    end

    test "returns a direction for a green line branch direction alert" do
      ie = ie(route: %Route{id: "Green-B", direction_names: ["West", "East"]}, direction_id: 1)

      assert %{full: "Eastbound", abbrev: "Eastbound"} = get_location([ie], "Green-B")
    end
  end
end
