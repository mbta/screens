defmodule ScreensWeb.PageControllerTest do
  use ScreensWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Welcome to Screens"
  end
end
