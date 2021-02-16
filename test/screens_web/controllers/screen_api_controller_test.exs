defmodule ScreensWeb.V2.ScreenApiControllerTest do
  use ScreensWeb.ConnCase

  describe "show/2" do
    test "returns ok", %{conn: conn} do
      %{status: status, resp_body: body} = get(conn, "/v2/api/screen/1")
      assert 200 == status
      assert "\"ok\"" == body
    end
  end
end
