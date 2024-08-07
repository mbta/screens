defmodule ScreensWeb.UserAgentTest do
  use ScreensWeb.ConnCase

  describe "screen_conn?/2" do
    test "returns true if is_real_screen query param is set to true" do
      conn =
        :get
        |> build_conn("/v2/api/screen/1", %{"is_real_screen" => "true"})
        |> put_req_header("user-agent", "fake")

      assert ScreensWeb.UserAgent.screen_conn?(conn, "1")
    end

    test "returns false if is_real_screen query param is set to false" do
      conn =
        :get
        |> build_conn("/v2/api/screen/1", %{"is_real_screen" => "false"})
        |> put_req_header("user-agent", "fake")

      refute ScreensWeb.UserAgent.screen_conn?(conn, "1")
    end

    test "returns false if is_real_screen query param is not set to true and user-agent unrecognized" do
      conn =
        :get
        |> build_conn("/v2/api/screen/1")
        |> put_req_header("user-agent", "fake")

      refute ScreensWeb.UserAgent.screen_conn?(conn, "1")
    end
  end
end
