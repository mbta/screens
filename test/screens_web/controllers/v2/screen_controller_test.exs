defmodule ScreensWeb.V2.ScreenControllerTest do
  use ScreensWeb.ConnCase

  alias Screens.Config.ScreenConfig
  alias Screens.Repo

  import Screens.TestSupport.ScreenConfigBuilder

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    :ok
  end

  describe "index/2" do
    test "returns 200", %{conn: conn} do
      screen_config = screen_config(:dup_v2)

      Repo.insert!(%ScreenConfig{
        id: "1401",
        config: screen_config
      })

      assert %{status: 200} = get(conn, "/v2/screen/1401")
    end
  end
end
