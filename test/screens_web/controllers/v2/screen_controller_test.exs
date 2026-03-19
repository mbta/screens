defmodule ScreensWeb.V2.ScreenControllerTest do
  use ScreensWeb.ConnCase

  import Mox
  setup :verify_on_exit!

  import Screens.Inject
  @cache injected(Screens.Config.Cache)

  describe "index/2" do
    test "returns 200", %{conn: conn} do
      expect(@cache, :screen, fn
        "1401" -> struct(ScreensConfig.Screen, app_id: :bus_shelter_v2)
      end)

      assert %{status: 200} = get(conn, "/v2/screen/1401")
    end
  end
end
