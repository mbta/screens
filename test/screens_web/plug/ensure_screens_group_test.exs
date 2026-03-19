defmodule ScreensWeb.Plug.EnsureScreensGroupTest do
  use ScreensWeb.ConnCase

  alias ScreensWeb.Plug.EnsureScreensGroup

  describe "init/1" do
    test "passes options through unchanged" do
      assert EnsureScreensGroup.init([]) == []
    end
  end

  describe "call/2" do
    @tag :authenticated
    test "does nothing when user is in the screens-admin group", %{conn: conn} do
      assert conn == EnsureScreensGroup.call(conn, [])
    end

    @tag :authenticated_not_in_group
    test "redirects when user is not in the screens-admin group", %{conn: conn} do
      conn = EnsureScreensGroup.call(conn, [])

      response = html_response(conn, 302)
      assert response =~ "/unauthorized"
    end
  end
end
