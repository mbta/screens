defmodule ScreensWeb.ScreensByAlertControllerTest do
  use ScreensWeb.ConnCase

  describe "index/2" do
    test "returns status code 200 and empty list in resp_body when no query param is provided", %{
      conn: conn
    } do
      conn = get(conn, "/api/screens_by_alert")
      assert %{status: 200, resp_body: "[]"} = conn
    end
  end

  test "returns status code 200 and empty list in resp_body when empty query param is provided",
       %{
         conn: conn
       } do
    conn = get(conn, "/api/screens_by_alert?ids=")
    assert %{status: 200, resp_body: "[]"} = conn
  end

  test "returns 200 in status when query param is provided", %{
    conn: conn
  } do
    conn = get(conn, "/api/screens_by_alert?ids=1,2,3")
    assert %{status: 200} = conn
  end
end
