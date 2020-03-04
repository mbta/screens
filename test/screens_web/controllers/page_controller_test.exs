defmodule ScreensWeb.PageControllerTest do
  use ScreensWeb.ConnCase

  test "GET /screen/<id>", %{conn: conn} do
    conn = get(conn, "/screen/1")
    assert html_response(conn, 200)
  end

  test "GET /screen/<id> with HTTP redirects to HTTPS", %{conn: conn} do
    conn = conn |> Plug.Conn.put_req_header("x-forwarded-proto", "http") |> get("/screen/1")

    location_header = Enum.find(conn.resp_headers, fn {key, _value} -> key == "location" end)
    {"location", url} = location_header
    assert url =~ "https"

    assert response(conn, 301)
  end
end
