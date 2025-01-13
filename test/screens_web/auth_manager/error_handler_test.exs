defmodule ScreensWeb.AuthManager.ErrorHandlerTest do
  use ScreensWeb.ConnCase

  describe "auth_error/3" do
    test "redirects to Keycloak login if there's no refresh key", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{})
        |> Phoenix.Controller.put_format("html")
        |> ScreensWeb.AuthManager.ErrorHandler.auth_error({:some_type, :reason}, [])

      assert redirected_to(conn) =~ "/auth/keycloak?prompt=login"
    end
  end
end
