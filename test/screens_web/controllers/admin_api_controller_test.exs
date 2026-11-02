defmodule ScreensWeb.AdminApiControllerTest do
  use ScreensWeb.ConnCase

  import ExUnit.CaptureLog
  import Mox
  import Screens.Inject
  import Screens.TestSupport.ScreenConfigBuilder

  alias Screens.Alerts.Alert
  alias Screens.Config.Backup.Store
  alias Screens.Config.ScreenConfig
  alias Screens.Repo
  alias ScreensConfig.{AlertSchedule, EvergreenContentItem, Schedule}
  alias ScreensConfig.Departures
  alias ScreensConfig.Departures.{Header, Section}
  alias ScreensConfig.Departures.Header.WayfindingInformation

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

  defp screen_with_wayfinding_end_dts(end_dts) do
    screen = screen_config(:busway_v2)

    item = %WayfindingInformation{
      image_path: "test-asset.png",
      schedule:
        Enum.map(end_dts, fn end_dt ->
          %Schedule{start_dt: ~U[2024-01-01 00:00:00Z], end_dt: end_dt}
        end)
    }

    %{
      screen
      | app_params: %{
          screen.app_params
          | departures: %Departures{
              sections: [%Section{header: %Header{wayfinding_information: item}, params: nil}]
            }
        }
    }
  end

  defp screen_with_alert_ids(alert_ids) do
    screen = screen_config(:busway_v2)

    item = %EvergreenContentItem{
      slot_names: [],
      asset_path: "test-asset.png",
      priority: 1,
      schedule: %AlertSchedule{alert_ids: alert_ids}
    }

    %{screen | app_params: %{screen.app_params | evergreen_content: [item]}}
  end

  setup :verify_on_exit!

  describe "unused asset cleanup" do
    @tag :authenticated
    test "previews eligible assets without deleting", %{conn: conn} do
      screen = screen_with_evergreen_end_dts([~U[2024-02-01 00:00:00Z]])
      Repo.insert!(%ScreenConfig{id: "retained", config: screen})

      expect(Screens.Assets.Cleanup.Mock, :preview, fn configs ->
        assert [%ScreenConfig{id: "retained", config: ^screen}] = configs
        {:ok, ["screens-local/images/unused.png"]}
      end)

      conn =
        post(conn, "/api/admin/maintenance", %{action: "unused_asset_cleanup", dry_run: true})

      assert json_response(conn, 200) == %{"keys" => ["screens-local/images/unused.png"]}
    end

    @tag :authenticated
    test "deletes confirmed keys using current configurations", %{conn: conn} do
      keys = ["screens-local/images/unused.png"]

      expect(Screens.Assets.Cleanup.Mock, :delete, fn [], ^keys -> {:ok, 1} end)

      conn = post(conn, "/api/admin/maintenance", %{action: "unused_asset_cleanup", keys: keys})
      assert json_response(conn, 200) == %{"success" => true, "deleted" => 1}
    end

    @tag :authenticated
    @tag :capture_log
    test "reports listing errors", %{conn: conn} do
      expect(Screens.Assets.Cleanup.Mock, :preview, fn [] -> {:error, :unavailable} end)

      conn =
        post(conn, "/api/admin/maintenance", %{action: "unused_asset_cleanup", dry_run: true})

      assert %{"success" => false, "error" => _} = json_response(conn, 502)
    end

    @tag :authenticated
    @tag :capture_log
    test "reports deletion errors", %{conn: conn} do
      expect(Screens.Assets.Cleanup.Mock, :delete, fn [], [] -> {:error, :forbidden} end)

      conn = post(conn, "/api/admin/maintenance", %{action: "unused_asset_cleanup", keys: []})
      assert %{"success" => false, "error" => _} = json_response(conn, 502)
    end

    @tag :authenticated
    @tag :capture_log
    test "rejects missing confirmation and invalid keys", %{conn: conn} do
      for params <- [%{}, %{dry_run: false}, %{keys: "invalid"}, %{keys: [1]}] do
        response =
          post(conn, "/api/admin/maintenance", Map.put(params, :action, "unused_asset_cleanup"))

        assert %{"success" => false} = json_response(response, 400)
      end
    end

    @tag :capture_log
    test "requires authentication", %{conn: conn} do
      conn =
        post(conn, "/api/admin/maintenance", %{action: "unused_asset_cleanup", dry_run: true})

      assert conn.status == 401
    end
  end

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

  describe "/cache" do
    @describetag :authenticated

    test "expires the cache for a screen ID", %{conn: conn} do
      expect(@data_cache, :invalidate, fn ["A"] -> {:ok, nil} end)

      conn = delete(conn, "/api/admin/cache/A")

      assert json_response(conn, 200) == %{"success" => true}
    end

    @tag :capture_log
    test "returns error code on error", %{conn: conn} do
      expect(@data_cache, :invalidate, fn ["B"] -> {:error, :oops} end)

      conn = delete(conn, "/api/admin/cache/B")

      assert json_response(conn, 200) == %{"success" => false, "error" => ":oops"}
    end
  end

  describe "/maintenance" do
    setup do
      before_date = ~D[2025-01-01]

      all_ended_evergreen_screen_config =
        screen_with_evergreen_end_dts([
          ~U[2024-10-03 00:00:00Z],
          ~U[2024-11-03 00:00:00Z]
        ])

      all_ended_wayfinding_screen_config =
        screen_with_wayfinding_end_dts([
          ~U[2024-10-03 00:00:00Z],
          ~U[2024-11-03 00:00:00Z]
        ])

      mixed_ended_evergreen_screen_config =
        screen_with_evergreen_end_dts([
          ~U[2024-10-03 00:00:00Z],
          ~U[2025-02-03 00:00:00Z]
        ])

      mixed_ended_wayfinding_screen_config =
        screen_with_wayfinding_end_dts([
          ~U[2024-10-03 00:00:00Z],
          ~U[2025-02-03 00:00:00Z]
        ])

      null_ended_evergreen_screen_config =
        screen_with_evergreen_end_dts([
          ~U[2024-10-03 00:00:00Z],
          nil
        ])

      null_ended_wayfinding_screen_config =
        screen_with_wayfinding_end_dts([
          ~U[2024-10-03 00:00:00Z],
          nil
        ])

      {:ok,
       before_date: before_date,
       all_ended_evergreen_screen_config: all_ended_evergreen_screen_config,
       all_ended_wayfinding_screen_config: all_ended_wayfinding_screen_config,
       mixed_ended_evergreen_screen_config: mixed_ended_evergreen_screen_config,
       mixed_ended_wayfinding_screen_config: mixed_ended_wayfinding_screen_config,
       null_ended_evergreen_screen_config: null_ended_evergreen_screen_config,
       null_ended_wayfinding_screen_config: null_ended_wayfinding_screen_config}
    end

    @tag :authenticated
    test "dry_run only counts configs with evergreen schedule end_dt before cutoff", %{
      conn: conn,
      before_date: before_date,
      all_ended_evergreen_screen_config: all_ended_evergreen_screen_config,
      mixed_ended_evergreen_screen_config: mixed_ended_evergreen_screen_config,
      null_ended_evergreen_screen_config: null_ended_evergreen_screen_config
    } do
      Repo.insert!(%ScreenConfig{
        id: "all-ended",
        config: all_ended_evergreen_screen_config
      })

      Repo.insert!(%ScreenConfig{
        id: "mixed-ended",
        config: mixed_ended_evergreen_screen_config
      })

      Repo.insert!(%ScreenConfig{
        id: "null-ended",
        config: null_ended_evergreen_screen_config
      })

      conn =
        post(conn, "/api/admin/maintenance", %{
          "action" => "image_content_cleanup",
          "before" => Date.to_iso8601(before_date),
          "dry_run" => "true"
        })

      assert json_response(conn, 200) == %{"affected" => 1}
    end

    @tag :authenticated
    test "only updates configs with all evergreen schedule end_dt before cutoff", %{
      conn: conn,
      before_date: before_date,
      all_ended_evergreen_screen_config: all_ended_evergreen_screen_config,
      mixed_ended_evergreen_screen_config: mixed_ended_evergreen_screen_config,
      null_ended_evergreen_screen_config: null_ended_evergreen_screen_config
    } do
      Repo.insert!(%ScreenConfig{id: "all-ended", config: all_ended_evergreen_screen_config})
      Repo.insert!(%ScreenConfig{id: "mixed-ended", config: mixed_ended_evergreen_screen_config})
      Repo.insert!(%ScreenConfig{id: "null-ended", config: null_ended_evergreen_screen_config})

      expect(@data_cache, :invalidate, fn ["all-ended"], fun -> {:ok, fun.()} end)

      conn =
        post(conn, "/api/admin/maintenance", %{
          "action" => "image_content_cleanup",
          "before" => Date.to_iso8601(before_date)
        })

      assert json_response(conn, 200) == %{"success" => true}

      assert Repo.get!(ScreenConfig, "all-ended").config.app_params.evergreen_content == []
      assert Repo.get!(ScreenConfig, "mixed-ended").config == mixed_ended_evergreen_screen_config
      assert Repo.get!(ScreenConfig, "null-ended").config == null_ended_evergreen_screen_config
    end

    @tag :authenticated
    test "dry_run only counts configs with wayfinding schedule end_dt before cutoff", %{
      conn: conn,
      before_date: before_date,
      all_ended_wayfinding_screen_config: all_ended_wayfinding_screen_config,
      mixed_ended_wayfinding_screen_config: mixed_ended_wayfinding_screen_config,
      null_ended_wayfinding_screen_config: null_ended_wayfinding_screen_config
    } do
      Repo.insert!(%ScreenConfig{
        id: "all-ended",
        config: all_ended_wayfinding_screen_config
      })

      Repo.insert!(%ScreenConfig{
        id: "mixed-ended",
        config: mixed_ended_wayfinding_screen_config
      })

      Repo.insert!(%ScreenConfig{
        id: "null-ended",
        config: null_ended_wayfinding_screen_config
      })

      conn =
        post(conn, "/api/admin/maintenance", %{
          "action" => "image_content_cleanup",
          "before" => Date.to_iso8601(before_date),
          "dry_run" => "true"
        })

      assert json_response(conn, 200) == %{"affected" => 1}
    end

    @tag :authenticated
    test "only updates configs with all wayfinding schedule end_dt before cutoff", %{
      conn: conn,
      before_date: before_date,
      all_ended_wayfinding_screen_config: all_ended_wayfinding_screen_config,
      mixed_ended_wayfinding_screen_config: mixed_ended_wayfinding_screen_config,
      null_ended_wayfinding_screen_config: null_ended_wayfinding_screen_config
    } do
      Repo.insert!(%ScreenConfig{id: "all-ended", config: all_ended_wayfinding_screen_config})
      Repo.insert!(%ScreenConfig{id: "mixed-ended", config: mixed_ended_wayfinding_screen_config})
      Repo.insert!(%ScreenConfig{id: "null-ended", config: null_ended_wayfinding_screen_config})

      expect(@data_cache, :invalidate, fn ["all-ended"], fun -> {:ok, fun.()} end)

      conn =
        post(conn, "/api/admin/maintenance", %{
          "action" => "image_content_cleanup",
          "before" => Date.to_iso8601(before_date)
        })

      assert json_response(conn, 200) == %{"success" => true}

      actual_all_ended_sections =
        Repo.get!(ScreenConfig, "all-ended").config.app_params.departures.sections

      assert length(actual_all_ended_sections) == 1
      assert is_nil(List.last(actual_all_ended_sections).header.wayfinding_information)
      assert Repo.get!(ScreenConfig, "mixed-ended").config == mixed_ended_wayfinding_screen_config
      assert Repo.get!(ScreenConfig, "null-ended").config == null_ended_wayfinding_screen_config
    end
  end

  describe "/maintenance alert_content_cleanup" do
    setup do
      Repo.insert!(%ScreenConfig{id: "expired", config: screen_with_alert_ids(["old"])})
      Repo.insert!(%ScreenConfig{id: "active", config: screen_with_alert_ids(["current"])})
      :ok
    end

    @tag :authenticated
    test "dry_run returns IDs of screens with content tied to expired alerts", %{conn: conn} do
      expect(Alert.Mock, :fetch, fn _opts -> {:ok, [%Alert{id: "current"}]} end)

      conn =
        post(conn, "/api/admin/maintenance", %{
          "action" => "alert_content_cleanup",
          "dry_run" => "true"
        })

      assert json_response(conn, 200) == %{"screen_ids" => ["expired"]}
    end

    @tag :authenticated
    test "removes content tied to expired alerts from the given screens", %{conn: conn} do
      expect(Alert.Mock, :fetch, fn opts ->
        assert opts[:ids] == ["old"]
        {:ok, []}
      end)

      expect(@data_cache, :invalidate, fn ["expired"], fun -> {:ok, fun.()} end)

      conn =
        post(conn, "/api/admin/maintenance", %{
          "action" => "alert_content_cleanup",
          "screen_ids" => ["expired"]
        })

      assert json_response(conn, 200) == %{"success" => true, "updated" => 1}
      assert Repo.get!(ScreenConfig, "expired").config.app_params.evergreen_content == []
      assert Repo.get!(ScreenConfig, "active").config == screen_with_alert_ids(["current"])
    end

    @tag :authenticated
    test "does not update configs when alerts cannot be fetched", %{conn: conn} do
      expect(Alert.Mock, :fetch, fn _opts -> :error end)

      capture_log(fn ->
        conn =
          post(conn, "/api/admin/maintenance", %{
            "action" => "alert_content_cleanup",
            "screen_ids" => ["expired"]
          })

        assert json_response(conn, 502)["success"] == false
      end)

      assert Repo.get!(ScreenConfig, "expired").config == screen_with_alert_ids(["old"])
    end
  end
end
