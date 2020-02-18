defmodule ScreensWeb.PageControllerTest do
  use ScreensWeb.ConnCase

  test "GET /screen", %{conn: conn} do
    conn = get(conn, "/screen")
    assert html_response(conn, 200)
  end

  test "GET /screen with HTTP redirects to HTTPS", %{conn: conn} do
    conn = conn |> Plug.Conn.put_req_header("x-forwarded-proto", "http") |> get("/screen")

    location_header = Enum.find(conn.resp_headers, fn {key, _value} -> key == "location" end)
    {"location", url} = location_header
    assert url =~ "https"

    assert response(conn, 301)
  end
end
