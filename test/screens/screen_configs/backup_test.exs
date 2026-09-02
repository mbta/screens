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

      {:ok, _} = Repo.insert(%ScreenConfig{id: "dup_1", config: config})

      now = ~U[2026-09-02 15:30:45Z]

      expect(Store.Mock, :put_backup, fn contents ->
        send(self(), {:put_backup, contents})
        :ok
      end)

      assert {:ok, %{count: 1}} = Backup.run(now)

      assert_received {:put_backup, contents}

      assert %{
               "meta" => %{"exported_at" => "2026-09-02T15:30:45Z"},
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
      expect(Store.Mock, :put_backup, fn _contents -> :error end)

      assert {:error, :backup_write_failed} = Backup.run(~U[2026-09-02 15:30:45Z])
    end
  end
end
