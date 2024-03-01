defmodule ScreensWeb.AuthManager.ErrorHandlerTest do
  use ScreensWeb.ConnCase

  describe "auth_error/3" do
    test "redirects to Cognito login if there's no refresh key", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{})
        |> ScreensWeb.AuthManager.ErrorHandler.auth_error({:some_type, :reason}, [])

      assert html_response(conn, 302) =~ "\"/auth/cognito\""
    end
  end
end
