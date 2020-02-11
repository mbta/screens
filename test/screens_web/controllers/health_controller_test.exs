defmodule ScreensWeb.HealthControllerTest do
  use ScreensWeb.ConnCase

  describe "index/2" do
    test "returns 200", %{conn: conn} do
      assert %{status: 200} = get(conn, "/_health")
    end
  end
end
