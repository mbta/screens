defmodule ScreensWeb.AdminApiControllerTest do
  use ScreensWeb.ConnCase

  import ExUnit.CaptureLog
  import Mox
  import Screens.Inject
  import Screens.TestSupport.ScreenConfigBuilder

  alias Screens.Config.Backup.Store
  alias Screens.Config.ScreenConfig
  alias Screens.Repo
  alias ScreensConfig.{EvergreenContentItem, Schedule}

  @data_cache injected(Screens.V2.ScreenData.Cache)

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
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

  describe "/backup_dates" do
    @tag :authenticated
    test "returns the current environment's daily backup dates", %{conn: conn} do
      expect(Store.Mock, :list_daily, fn "screens-local" ->
        {:ok, ["2026-09-24", "2026-09-23"]}
      end)

      conn = get(conn, "/api/admin/backup_dates")

      assert json_response(conn, 200) == %{
               "dates" => ["2026-09-24", "2026-09-23"]
             }
    end

    @tag :authenticated
    test "compares current configs with the selected daily backup", %{conn: conn} do
      current_config = screen_config(:busway_v2)
      backup_config = screen_config_json(:dup_v2)
      Repo.insert!(%ScreenConfig{id: "current-screen", config: current_config})

      expect(Store.Mock, :fetch_daily, fn "screens-local", ~D[2026-09-23] ->
        {:ok, Jason.encode!(%{screens: %{"backup-screen" => backup_config}})}
      end)

      conn = post(conn, "/api/admin/daily_backup_comparison", %{date: "2026-09-23"})

      assert %{
               "current" => %{"current-screen" => _current},
               "backup" => %{"backup-screen" => _backup},
               "differing_ids" => ["backup-screen", "current-screen"]
             } = json_response(conn, 200)

      assert Repo.get(ScreenConfig, "current-screen")
      refute Repo.get(ScreenConfig, "backup-screen")
    end

    @tag :authenticated
    test "restores screen configs from the selected daily backup", %{conn: conn} do
      restored_config = screen_config_json(:dup_v2)

      expect(Store.Mock, :fetch_daily, fn "screens-local", ~D[2026-09-23] ->
        {:ok, Jason.encode!(%{screens: %{"restored-screen" => restored_config}})}
      end)

      expect(@data_cache, :invalidate, fn ["restored-screen"], fun -> {:ok, fun.()} end)

      conn = post(conn, "/api/admin/restore_daily_backup", %{date: "2026-09-23"})

      assert json_response(conn, 200) == %{
               "success" => true,
               "upserted" => 1,
               "deleted" => 0
             }

      assert Repo.get(ScreenConfig, "restored-screen")
    end
  end

  describe "screen config admin endpoints" do
    @tag :authenticated
    test "updates screen configs in Postgres", %{conn: conn} do
      screen_dup_config = screen_config(:dup_v2)
      screen_busway_config = screen_config(:busway_v2)

      Repo.insert!(%ScreenConfig{id: "screen-1", config: screen_busway_config})
      expect(@data_cache, :invalidate, fn ["screen-1"], fun -> {:ok, fun.()} end)

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
    test "returns 400 when screen_configs param is missing", %{conn: conn} do
      capture_log([level: :warning], fn ->
        conn = post(conn, "/api/admin/screen_configs/update", %{})
        assert conn.status == 400
      end)
    end

    @tag :authenticated
    test "deletes screen configs in Postgres", %{conn: conn} do
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
    test "index endpoint returns Postgres screen configs", %{conn: conn} do
      config = screen_config(:dup_v2)
      Repo.insert!(%ScreenConfig{id: "screen-1", config: config})

      conn = get(conn, "/api/admin")

      assert %{"config" => config_json} = response = json_response(conn, 200)
      assert Map.keys(response) == ["config"]

      assert Jason.decode!(config_json) == %{
               "screens" => %{"screen-1" => normalize_json(ScreensConfig.Screen.to_json(config))}
             }
    end
  end

  describe "/refresh" do
    @tag :authenticated
    test "schedules a Postgres screen refresh at the specified time", %{conn: conn} do
      Repo.insert!(%ScreenConfig{id: "screen-1", config: screen_config(:dup_v2)})
      Repo.insert!(%ScreenConfig{id: "screen-2", config: screen_config(:busway_v2)})
      expect(@data_cache, :invalidate, fn ["screen-1"], fun -> {:ok, fun.()} end)

      conn = post(conn, "/api/admin/refresh", %{screen_ids: ["screen-1"]})

      assert json_response(conn, 200) == %{"success" => true}
      assert Repo.get!(ScreenConfig, "screen-1").config.refresh_if_loaded_before
      refute Repo.get!(ScreenConfig, "screen-2").config.refresh_if_loaded_before
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
      Repo.insert!(%ScreenConfig{id: "all-ended", config: all_ended_screen_config})
      Repo.insert!(%ScreenConfig{id: "mixed-ended", config: mixed_ended_screen_config})
      Repo.insert!(%ScreenConfig{id: "null-ended", config: null_ended_screen_config})

      expect(@data_cache, :invalidate, fn ["all-ended"], fun -> {:ok, fun.()} end)

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
end
