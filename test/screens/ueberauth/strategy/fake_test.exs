defmodule Screens.Ueberauth.Strategy.FakeTest do
  use ExUnit.Case
  use Plug.Test
  import Screens.Ueberauth.Strategy.Fake

  describe "implements all the callbacks" do
    test "handle_request!/1" do
      conn =
        conn(:get, "/auth/cognito")
        |> init_test_session(%{})
        |> handle_request!()

      assert conn.status == 302
    end

    test "handle_callback!/1" do
      conn = conn(:get, "/auth/cognito/callback")

      assert ^conn = handle_callback!(conn)
    end

    test "uid/1" do
      conn = conn(:get, "/auth/cognito/callback")

      assert uid(conn) == "fake_uid"
    end

    test "credentials/1" do
      conn = conn(:get, "/auth/cognito/callback")

      assert %Ueberauth.Auth.Credentials{other: %{}} = credentials(conn)
    end

    test "info/1" do
      conn = conn(:get, "/auth/cognito/callback")

      assert %Ueberauth.Auth.Info{} = info(conn)
    end

    test "extra/1" do
      conn = conn(:get, "/auth/cognito/callback")

      assert %Ueberauth.Auth.Extra{} = extra(conn)
    end
  end
end
