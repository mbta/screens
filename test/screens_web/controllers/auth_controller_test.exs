defmodule ScreensWeb.Controllers.AuthControllerTest do
  use ScreensWeb.ConnCase

  import ExUnit.CaptureLog

  describe "callback" do
    test "redirects on success and saves refresh token", %{conn: conn} do
      conn =
        get(
          conn,
          ~p"/auth/keycloak/callback?#{[email: "user@test.com", roles: ["screens-admin"]]}"
        )

      response = html_response(conn, 302)

      assert response =~ ~p"/admin"
    end

    test "handles generic failure", %{conn: conn} do
      logs =
        capture_log([level: :warning], fn ->
          conn =
            conn
            |> assign(:ueberauth_failure, %Ueberauth.Failure{})
            |> get(ScreensWeb.Router.Helpers.auth_path(conn, :callback, "keycloak"))

          assert response(conn, 401) =~ "unauthenticated"
        end)

      assert logs =~ "ueberauth_failure"
    end
  end

  describe "request" do
    test "redirects to auth callback", %{conn: conn} do
      conn = get(conn, ScreensWeb.Router.Helpers.auth_path(conn, :request, "keycloak"))

      response = response(conn, 302)

      assert response =~ ScreensWeb.Router.Helpers.auth_path(conn, :callback, "keycloak")
    end
  end
end
