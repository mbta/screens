defmodule Screens.ScreenConfigs.BackupTest do
  use ExUnit.Case

  import Mox
  import Screens.TestSupport.ScreenConfigBuilder

  alias Screens.Config.Backup
  alias Screens.Config.Backup.Store
  alias Screens.Config.ScreenConfig
  alias Screens.Repo
  alias ScreensConfig.Screen

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    :ok
  end

  setup :verify_on_exit!

  describe "dates/0" do
    test "lists the current environment's daily backups newest first" do
      expect(Store.Mock, :list_daily, fn "screens-local" ->
        {:ok, ["2026-09-22", "2026-09-24", "2026-09-23"]}
      end)

      assert {:ok, ["2026-09-24", "2026-09-23", "2026-09-22"]} = Backup.dates()
    end

    test "returns an error when listing daily backups fails" do
      expect(Store.Mock, :list_daily, fn "screens-local" -> :error end)

      assert :error = Backup.dates()
    end
  end

  describe "restore_daily/1" do
    test "replaces Postgres configs with the selected daily backup" do
      existing_config = screen_config(:busway_v2)
      restored_config = screen_config_json(:dup_v2)
      Repo.insert!(%ScreenConfig{id: "old-screen", config: existing_config})

      expect(Store.Mock, :fetch_daily, fn "screens-local", ~D[2026-09-23] ->
        {:ok, Jason.encode!(%{screens: %{"restored-screen" => restored_config}})}
      end)

      expect(Screens.V2.ScreenData.Cache.Mock, :invalidate, fn
        ["restored-screen", "old-screen"], fun -> {:ok, fun.()}
      end)

      assert {:ok, %{upserted: 1, deleted: 1}} = Backup.restore_daily("2026-09-23")
      refute Repo.get(ScreenConfig, "old-screen")
      assert Repo.get(ScreenConfig, "restored-screen")
    end

    test "rejects an invalid date without fetching a backup" do
      assert {:error, :invalid_date} = Backup.restore_daily("../../latest/prod")
    end

    test "does not count an unchanged config as upserted" do
      config = screen_config(:busway_v2)
      Repo.insert!(%ScreenConfig{id: "unchanged-screen", config: config})

      expect(Store.Mock, :fetch_daily, fn "screens-local", ~D[2026-09-23] ->
        {:ok,
         Jason.encode!(%{
           screens: %{"unchanged-screen" => ScreensConfig.Screen.to_json(config)}
         })}
      end)

      assert {:ok, %{upserted: 0, deleted: 0}} = Backup.restore_daily("2026-09-23")
    end
  end

  describe "compare_daily/1" do
    test "returns only differing current and backup configs without restoring" do
      current_config = screen_config(:busway_v2)
      backup_config = screen_config_json(:dup_v2)
      normalized_backup_config = normalize_json(backup_config)
      Repo.insert!(%ScreenConfig{id: "current-screen", config: current_config})
      Repo.insert!(%ScreenConfig{id: "unchanged-screen", config: current_config})

      expect(Store.Mock, :fetch_daily, fn "screens-local", ~D[2026-09-23] ->
        {:ok,
         Jason.encode!(%{
           screens: %{
             "backup-screen" => backup_config,
             "unchanged-screen" => ScreensConfig.Screen.to_json(current_config)
           }
         })}
      end)

      assert {:ok,
              %{
                current: %{"current-screen" => current_json},
                backup: %{"backup-screen" => ^normalized_backup_config},
                differing_ids: ["backup-screen", "current-screen"]
              }} = Backup.compare_daily("2026-09-23")

      assert current_json == normalize_json(ScreensConfig.Screen.to_json(current_config))
      assert Repo.get(ScreenConfig, "current-screen")
      assert Repo.get(ScreenConfig, "unchanged-screen")
      refute Repo.get(ScreenConfig, "backup-screen")
    end
  end

  describe "run/1" do
    test "writes the current configs to the backup store" do
      config_json = :dup_v2 |> screen_config_json() |> normalize_json()
      config = Screen.from_json(config_json)

      {:ok, %ScreenConfig{updated_at: updated_at}} =
        Repo.insert(%ScreenConfig{id: "dup_1", config: config})

      # Set export time to just before the last update time, so that the backup is considered out of date.
      last_export_iso =
        updated_at
        |> DateTime.from_naive!("Etc/UTC")
        |> DateTime.add(-1, :second)
        |> DateTime.to_iso8601()

      updated_at_iso = DateTime.to_iso8601(updated_at)

      backup_json =
        Jason.encode!(%{
          meta: %{environment: "test", exported_at: last_export_iso},
          screens: config_json
        })

      expect(Store.Mock, :fetch_latest, fn _environment -> {:ok, backup_json} end)

      expect(Store.Mock, :put_latest, fn contents ->
        send(self(), {:put_backup, contents})
        :ok
      end)

      assert {:ok, %{count: 1}} = Backup.capture_latest(updated_at)

      assert_received {:put_backup, contents}

      assert %{
               "meta" => %{"exported_at" => ^updated_at_iso},
               "screens" => %{"dup_1" => ^config_json}
             } = Jason.decode!(contents)
    end

    test "returns an error when the write fails" do
      expect(Store.Mock, :fetch_latest, fn _environment -> :error end)
      expect(Store.Mock, :put_latest, fn _contents -> :error end)

      assert {:error, :backup_write_failed} =
               Backup.capture_latest(~U[2026-09-02 15:30:45Z])
    end

    test "skips writing a backup when no config has changed since the last export" do
      config_json = :dup_v2 |> screen_config_json() |> normalize_json()
      config = Screen.from_json(config_json)

      {:ok, %ScreenConfig{updated_at: updated_at}} =
        Repo.insert(%ScreenConfig{id: "dup_1", config: config})

      exported_at = DateTime.add(DateTime.from_naive!(updated_at, "Etc/UTC"), 1, :second)

      backup_json =
        Jason.encode!(%{
          meta: %{environment: "test", exported_at: DateTime.to_iso8601(exported_at)},
          screens: %{"dup_1" => config_json}
        })

      expect(Store.Mock, :fetch_latest, fn _environment -> {:ok, backup_json} end)

      assert {:ok, :skipped} = Backup.capture_latest(~U[2026-09-02 15:30:45Z])
    end
  end

  describe "run_daily_snapshot/1" do
    test "writes the current configs to a dated snapshot" do
      config_json = :dup_v2 |> screen_config_json() |> normalize_json()
      config = Screen.from_json(config_json)
      Repo.insert!(%ScreenConfig{id: "dup_1", config: config})

      expect(Store.Mock, :put_daily, fn contents, ~D[2026-09-02] ->
        send(self(), {:put_daily, contents})
        :ok
      end)

      assert {:ok, %{count: 1}} = Backup.capture_daily(~U[2026-09-02 15:30:45Z])
      assert_received {:put_daily, contents}

      assert %{
               "meta" => %{"exported_at" => "2026-09-02T15:30:45Z"},
               "screens" => %{"dup_1" => ^config_json}
             } = Jason.decode!(contents)
    end
  end
end
