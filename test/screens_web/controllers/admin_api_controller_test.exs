defmodule ScreensWeb.AdminApiControllerTest do
  use ScreensWeb.ConnCase

  import ExUnit.CaptureLog
  import Mox
  import Screens.TestSupport.ScreenConfigBuilder

  alias Screens.Config.ScreenConfig
  alias Screens.Repo
  alias ScreensConfig.{EvergreenContentItem, Schedule}

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)

    previous_config_migration = Application.get_env(:screens, :config_migration)

    on_exit(fn ->
      restore_app_env(:screens, :config_migration, previous_config_migration)
    end)

    :ok
  end

  defp screen_with_evergreen_end_dts(end_dts) do
    screen = screen_config(:busway_v2)

    item = %EvergreenContentItem{
      slot_names: [],
      asset_path: "test-asset.png",
      priority: 1,
      schedule:
        Enum.map(end_dts, fn end_dt ->
          %Schedule{start_dt: ~U[2024-01-01 00:00:00Z], end_dt: end_dt}
        end)
    }

    %{screen | app_params: %{screen.app_params | evergreen_content: [item]}}
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

  describe "/maintenance" do
    setup do
      before_date = ~D[2025-01-01]

      all_ended_screen_config =
        screen_with_evergreen_end_dts([
          ~U[2024-10-03 00:00:00Z],
          ~U[2024-11-03 00:00:00Z]
        ])

      mixed_ended_screen_config =
        screen_with_evergreen_end_dts([
          ~U[2024-10-03 00:00:00Z],
          ~U[2025-02-03 00:00:00Z]
        ])

      null_ended_screen_config =
        screen_with_evergreen_end_dts([
          ~U[2024-10-03 00:00:00Z],
          nil
        ])

      {:ok,
       before_date: before_date,
       all_ended_screen_config: all_ended_screen_config,
       mixed_ended_screen_config: mixed_ended_screen_config,
       null_ended_screen_config: null_ended_screen_config}
    end

    @tag :authenticated
    test "dry_run only counts configs with evergreen schedule end_dt before cutoff", %{
      conn: conn,
      before_date: before_date,
      all_ended_screen_config: all_ended_screen_config,
      mixed_ended_screen_config: mixed_ended_screen_config,
      null_ended_screen_config: null_ended_screen_config
    } do
      Application.put_env(:screens, :config_migration, true)

      Repo.insert!(%ScreenConfig{
        id: "all-ended",
        config: all_ended_screen_config
      })

      Repo.insert!(%ScreenConfig{
        id: "mixed-ended",
        config: mixed_ended_screen_config
      })

      Repo.insert!(%ScreenConfig{
        id: "null-ended",
        config: null_ended_screen_config
      })

      conn =
        post(conn, "/api/admin/maintenance", %{
          "action" => "content_cleanup",
          "before" => Date.to_iso8601(before_date),
          "dry_run" => "true"
        })

      assert json_response(conn, 200) == %{"affected" => 1}
    end

    @tag :authenticated
    test "only updates configs with all evergreen schedule end_dt before cutoff", %{
      conn: conn,
      before_date: before_date,
      all_ended_screen_config: all_ended_screen_config,
      mixed_ended_screen_config: mixed_ended_screen_config,
      null_ended_screen_config: null_ended_screen_config
    } do
      Application.put_env(:screens, :config_migration, true)

      Repo.insert!(%ScreenConfig{id: "all-ended", config: all_ended_screen_config})
      Repo.insert!(%ScreenConfig{id: "mixed-ended", config: mixed_ended_screen_config})
      Repo.insert!(%ScreenConfig{id: "null-ended", config: null_ended_screen_config})

      conn =
        post(conn, "/api/admin/maintenance", %{
          "action" => "content_cleanup",
          "before" => Date.to_iso8601(before_date)
        })

      assert json_response(conn, 200) == %{"success" => true}

      assert Repo.get!(ScreenConfig, "all-ended").config.app_params.evergreen_content == []
      assert Repo.get!(ScreenConfig, "mixed-ended").config == mixed_ended_screen_config
      assert Repo.get!(ScreenConfig, "null-ended").config == null_ended_screen_config
    end
  end

  defp restore_app_env(app, key, nil), do: Application.delete_env(app, key)
  defp restore_app_env(app, key, value), do: Application.put_env(app, key, value)
end
