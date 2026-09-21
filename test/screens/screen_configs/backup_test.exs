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
