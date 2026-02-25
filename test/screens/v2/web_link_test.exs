defmodule Screens.V2.WebLinkTest do
  use ExUnit.Case, async: true

  describe "alternate_route_url/1" do
    test "returns alerts URL if the vanity URL is nil or empty" do
      vanity_url = nil
      assert "mbta.com/alerts" == Screens.V2.WebLink.alternate_route_url(vanity_url)

      vanity_url = ""
      assert "mbta.com/alerts" == Screens.V2.WebLink.alternate_route_url(vanity_url)
    end

    test "returns URL with removed 'https' and 'www' if vanity_url exists" do
      vanity_url = "https://www.mbta.com/OrangeLine"
      assert "mbta.com/OrangeLine" == Screens.V2.WebLink.alternate_route_url(vanity_url)

      vanity_url = "www.mbta.com/OrangeLine"
      assert "mbta.com/OrangeLine" == Screens.V2.WebLink.alternate_route_url(vanity_url)
    end
  end
end
