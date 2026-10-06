defmodule Screens.V2.WidgetInstance.SubwayStatus.Serialize.UtilsTest do
  use ExUnit.Case

  alias Screens.Routes.Route

  import Screens.V2.WidgetInstance.SubwayStatus.Serialize.Utils
  import Screens.TestSupport.InformedEntityBuilder

  describe "get_location/2" do
    test "returns a direction for a whole direction alert" do
      ie = ie(route: %Route{id: "Blue", direction_names: ["West", "East"]}, direction_id: 0)

      assert %{full: "Westbound", abbrev: "Westbound"} = get_location([ie], "Blue")
    end
  end
end
