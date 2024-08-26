defmodule ScreensWeb.Controllers.AuthControllerTest do
  use ScreensWeb.ConnCase

  describe "callback" do
    test "redirects on success and saves refresh token", %{conn: conn} do
      current_time = System.system_time(:second)

      auth = %Ueberauth.Auth{
        uid: "foo@mbta.com",
        credentials: %Ueberauth.Auth.Credentials{
          expires_at: current_time + 1_000
        },
        extra: %{
          raw_info: %{
            userinfo: %{
              "resource_access" => %{
                "test-client" => %{"roles" => ["screens-admin"]}
              }
            }
          }
        }
      }

      conn =
        conn
        |> assign(:ueberauth_auth, auth)
        |> get(ScreensWeb.Router.Helpers.auth_path(conn, :callback, "keycloak"))

      response = html_response(conn, 302)

      assert response =~ ~p"/admin"
      assert Guardian.Plug.current_claims(conn)["roles"] == ["screens-admin"]
    end

    test "handles generic failure", %{conn: conn} do
      conn =
        conn
        |> assign(:ueberauth_failure, %Ueberauth.Failure{})
        |> get(ScreensWeb.Router.Helpers.auth_path(conn, :callback, "keycloak"))

      response = response(conn, 401)

      assert response =~ "unauthenticated"
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
