defmodule ScreensWeb.Plug.EnsureBearerTokenTest do
  use ScreensWeb.ConnCase

  alias ScreensWeb.Plug.EnsureBearerToken

  @env_var "SCREENS_API_CLIENT_KEY"

  setup do
    previous_value = System.get_env(@env_var)

    on_exit(fn ->
      restore_env_var(@env_var, previous_value)
    end)

    :ok
  end

  describe "init/1" do
    test "returns configured env var name" do
      assert EnsureBearerToken.init(env_var: @env_var) == @env_var
    end
  end

  describe "call/2" do
    test "allows request when bearer token matches configured token", %{conn: conn} do
      System.put_env(@env_var, "shared-secret")

      conn =
        conn
        |> put_req_header("authorization", "Bearer shared-secret")
        |> EnsureBearerToken.call(@env_var)

      refute conn.halted
    end

    test "halts with 401 when authorization header is missing", %{conn: conn} do
      System.put_env(@env_var, "shared-secret")

      conn = EnsureBearerToken.call(conn, @env_var)

      assert conn.halted
      assert conn.status == 401
      assert conn.resp_body == "{\"error\":\"unauthorized\"}"
    end

    test "halts with 401 when bearer token does not match", %{conn: conn} do
      System.put_env(@env_var, "shared-secret")

      conn =
        conn
        |> put_req_header("authorization", "Bearer wrong-secret")
        |> EnsureBearerToken.call(@env_var)

      assert conn.halted
      assert conn.status == 401
    end

    test "halts with 401 when configured token is unavailable", %{conn: conn} do
      System.delete_env(@env_var)

      conn =
        conn
        |> put_req_header("authorization", "Bearer shared-secret")
        |> EnsureBearerToken.call(@env_var)

      assert conn.halted
      assert conn.status == 401
    end
  end

  defp restore_env_var(env_var, nil), do: System.delete_env(env_var)
  defp restore_env_var(env_var, value), do: System.put_env(env_var, value)
end
