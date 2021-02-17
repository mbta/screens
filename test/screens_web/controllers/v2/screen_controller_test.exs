defmodule ScreensWeb.V2.ScreenControllerTest do
  use ScreensWeb.ConnCase

  describe "index/2" do
    test "returns 200", %{conn: conn} do
      assert %{status: 200} = get(conn, "/v2/screen/1")
    end
  end
end
