defmodule ScreensWeb.V2.ScreenControllerTest do
  use ScreensWeb.ConnCase

  import Mox
  setup :verify_on_exit!

  alias Screens.Config.ScreenConfig
  alias Screens.Repo

  import Screens.Inject
  import Screens.TestSupport.ScreenConfigBuilder

  @cache injected(Screens.Config.Cache)

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)

    previous_config_migration = Application.get_env(:screens, :config_migration)
    Application.put_env(:screens, :config_migration, false)

    on_exit(fn ->
      restore_app_env(:screens, :config_migration, previous_config_migration)
    end)

    :ok
  end

  describe "index/2" do
    test "returns 200", %{conn: conn} do
      expect(@cache, :screen, fn
        "1401" -> struct(ScreensConfig.Screen, app_id: :bus_shelter_v2)
      end)

      assert %{status: 200} = get(conn, "/v2/screen/1401")
    end

    test "returns 200 when config migration is true", %{conn: conn} do
      Application.put_env(:screens, :config_migration, true)

      screen_config = screen_config(:dup_v2)

      Repo.insert!(%ScreenConfig{
        id: "1401",
        config: screen_config
      })

      assert %{status: 200} = get(conn, "/v2/screen/1401")
    end
  end

  defp restore_app_env(app, key, nil), do: Application.delete_env(app, key)
  defp restore_app_env(app, key, value), do: Application.put_env(app, key, value)
end
