defmodule ScreensWeb.Controllers.AuthControllerTest do
  use ScreensWeb.ConnCase

  import ExUnit.CaptureLog

  describe "callback" do
    test "redirects on success and saves refresh token", %{conn: conn} do
      current_time = System.system_time(:second)

      auth = %Ueberauth.Auth{
        provider: :keycloak,
        uid: "foo@mbta.com",
        credentials: %Ueberauth.Auth.Credentials{
          expires_at: current_time + 1_000
        },
        extra: %Ueberauth.Auth.Extra{
          raw_info: %UeberauthOidcc.RawInfo{
            claims: %{
              "iat" => System.system_time(:second)
            },
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
