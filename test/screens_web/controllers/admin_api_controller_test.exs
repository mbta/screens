defmodule ScreensWeb.AdminApiControllerTest do
  use ScreensWeb.ConnCase

  import ExUnit.CaptureLog
  import Mox
  import Screens.TestSupport.ScreenConfigBuilder

  alias Screens.Config.ScreenConfig
  alias Screens.Repo

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)

    previous_config_migration = Application.get_env(:screens, :config_migration)

    on_exit(fn ->
      restore_app_env(:screens, :config_migration, previous_config_migration)
    end)

    :ok
  end

  setup :verify_on_exit!

  describe "screen config admin endpoints" do
    @tag :authenticated
    test "updates screen configs in Postgres when migration flag is true", %{conn: conn} do
      Application.put_env(:screens, :config_migration, true)

      screen_dup_config = screen_config(:dup_v2)
      screen_busway_config = screen_config(:busway_v2)

      Repo.insert!(%ScreenConfig{id: "screen-1", config: screen_busway_config})

      conn =
        post(conn, "/api/admin/screen_configs/update", %{
          screen_configs: [
            %{id: "screen-1", config: screen_dup_config}
          ]
        })

      assert json_response(conn, 200) == %{"success" => true}

      updated = Repo.get!(ScreenConfig, "screen-1")
      assert updated.config == screen_dup_config
    end

    @tag :authenticated
    test "updates full config when migration flag is false", %{conn: conn} do
      Application.put_env(:screens, :config_migration, false)

      screen_busway_config = screen_config_json(:busway_v2)

      # Mock the fetch and put to prevent writing to the fixture file
      expect(Screens.Config.Fetch.Mock, :fetch_config, fn ->
        {:ok, ~s({"screens": {"screen-2": {"app_id": "dup_v2"}}}), 1}
      end)

      expect(Screens.Config.Fetch.Mock, :put_config, fn _config -> :ok end)

      conn =
        post(conn, "/api/admin/screen_configs/update", %{
          screen_configs: [
            %{"id" => "screen-2", "config" => screen_busway_config}
          ]
        })

      assert json_response(conn, 200) == %{"success" => true}
    end

    @tag :authenticated
    test "returns 400 when screen_configs param is missing", %{conn: conn} do
      capture_log([level: :warning], fn ->
        conn = post(conn, "/api/admin/screen_configs/update", %{})
        assert conn.status == 400
      end)
    end

    @tag :authenticated
    test "deletes screen configs in Postgres when migration flag is true", %{conn: conn} do
      Application.put_env(:screens, :config_migration, true)

      screen_dup_config = screen_config(:dup_v2)
      screen_busway_config = screen_config(:busway_v2)

      Repo.insert!(%ScreenConfig{id: "screen-1", config: screen_dup_config})
      Repo.insert!(%ScreenConfig{id: "screen-2", config: screen_busway_config})

      conn =
        post(conn, "/api/admin/screen_configs/delete", %{
          deleted_screen_ids: ["screen-2"]
        })

      assert json_response(conn, 200) == %{"success" => true}
      assert Repo.get(ScreenConfig, "screen-1")
      assert nil == Repo.get(ScreenConfig, "screen-2")
    end

    @tag :authenticated
    test "returns 400 when deleted_screen_ids param is missing", %{conn: conn} do
      capture_log([level: :warning], fn ->
        conn = post(conn, "/api/admin/screen_configs/delete", %{})
        assert conn.status == 400
      end)
    end

    @tag :authenticated
    test "index endpoint returns config_migration flag", %{conn: conn} do
      Application.put_env(:screens, :config_migration, true)

      conn = get(conn, "/api/admin")

      assert conn.status == 200
      %{"config_migration" => config_migration} = json_response(conn, 200)
      assert config_migration == true
    end
  end

  defp restore_app_env(app, key, nil), do: Application.delete_env(app, key)
  defp restore_app_env(app, key, value), do: Application.put_env(app, key, value)
end
