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

      expect(Store.Mock, :fetch_backup, fn _environment -> {:ok, backup_json} end)

      expect(Store.Mock, :put_backup, fn contents ->
        send(self(), {:put_backup, contents})
        :ok
      end)

      assert {:ok, %{count: 1}} = Backup.run(updated_at)

      assert_received {:put_backup, contents}

      assert %{
               "meta" => %{"exported_at" => ^updated_at_iso},
               "screens" => %{"dup_1" => ^config_json}
             } = Jason.decode!(contents)
    end

    test "does nothing and returns :locked when another instance is already running a backup" do
      test_pid = self()

      # Run test async so that other tests don't run while it's holding the lock.
      task =
        Task.async(fn ->
          :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)

          Repo.transaction(fn ->
            # `1` is the same cron lock key `Backup.run/1` uses internally
            Repo.query!("SELECT pg_advisory_xact_lock($1)", [1])
            send(test_pid, :locked)

            receive do
              :release -> :ok
            end
          end)

          Ecto.Adapters.SQL.Sandbox.checkin(Repo)
        end)

      assert_receive :locked

      assert {:ok, :locked} = Backup.run(~U[2026-09-02 15:30:45Z])

      send(task.pid, :release)
      Task.await(task)
    end

    test "returns an error when the write fails" do
      expect(Store.Mock, :fetch_backup, fn _environment -> :error end)
      expect(Store.Mock, :put_backup, fn _contents -> :error end)

      assert {:error, :backup_write_failed} = Backup.run(~U[2026-09-02 15:30:45Z])
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

      expect(Store.Mock, :fetch_backup, fn _environment -> {:ok, backup_json} end)

      assert {:ok, :skipped} = Backup.run(~U[2026-09-02 15:30:45Z])
    end
  end
end
