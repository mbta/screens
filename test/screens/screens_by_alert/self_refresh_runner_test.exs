defmodule Screens.ScreensByAlert.SelfRefreshRunnerTest do
  use ExUnit.Case, async: true

  alias Screens.Config.ScreenConfig
  alias Screens.Repo
  alias Screens.ScreensByAlert
  alias Screens.ScreensByAlert.SelfRefreshRunner
  alias Screens.V2.ScreenData
  alias ScreensConfig.Screen

  import Mox
  import Screens.TestSupport.ScreenConfigBuilder
  import Screens.Inject

  @cache injected(Screens.Config.Cache)

  setup :verify_on_exit!

  setup do
    previous_config_migration = Application.get_env(:screens, :config_migration)
    Application.put_env(:screens, :config_migration, false)

    stub(@cache, :screen, fn
      "1401" -> struct(Screen, app_id: :bus_shelter_v2)
      "1002" -> struct(Screen, app_id: :bus_eink_v2)
      _id -> struct(Screen)
    end)

    on_exit(fn ->
      restore_app_env(:screens, :config_migration, previous_config_migration)
    end)

    :ok
  end

  # NOTE: Screen IDs used in these tests come from `test/fixtures/config.json`

  @tag :capture_log
  test "refreshes a batch of the most-outdated screens" do
    now = System.system_time(:second)

    expect(ScreensByAlert.Mock, :get_screens_last_updated, fn _screen_ids ->
      %{"1001" => now - 61, "1002" => now - 62, "1301" => now - 63, "1401" => now - 64}
    end)

    # Pretend another instance is refreshing 1301. Per the batch size in test, the 2 most outdated
    # screens should be refreshed (that are not already being refreshed), which are 1401 and 1002.
    expect(ScreensByAlert.Mock, :get_in_progress, fn _screen_ids -> ["1301"] end)
    expect(ScreensByAlert.Mock, :put_in_progress, fn ~w[1401 1002] -> :ok end)

    expect(ScreenData.Mock, :get, fn "1401", %Screen{app_id: :bus_shelter_v2} -> %{type: :x} end)
    expect(ScreenData.Mock, :get, fn "1002", %Screen{app_id: :bus_eink_v2} -> raise "oops" end)

    screen_ids = MapSet.new(~w[1002 1401])
    assert {:noreply, ^screen_ids} = SelfRefreshRunner.handle_info(:check, MapSet.new())

    # Wait longer than the default 100ms to avoid occasional timeouts
    assert_receive({:done, :ok, "1401"}, 200)
    assert_receive({:done, :exit, "1002"}, 200)
  end

  test "skips refreshing if any refreshes are in progress" do
    screen_ids = MapSet.new(~w[1001])
    assert {:noreply, ^screen_ids} = SelfRefreshRunner.handle_info(:check, screen_ids)
  end

  test "tracks when queued refreshes are completed" do
    screen_ids = MapSet.new(~w[1001 1002])
    new_screen_ids = MapSet.new(~w[1002])

    assert {:noreply, ^new_screen_ids} =
             SelfRefreshRunner.handle_info({:done, :ok, "1001"}, screen_ids)
  end

  @tag :capture_log
  test "uses Postgres-backed eligible screen IDs when config migration is true" do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Application.put_env(:screens, :config_migration, true)

    base_screen = screen_config(:dup_v2)
    disabled_screen = %{base_screen | disabled: true}
    hidden_screen = %{base_screen | hidden_from_screenplay: true}

    Repo.insert!(%ScreenConfig{id: "eligible", config: base_screen})
    Repo.insert!(%ScreenConfig{id: "disabled", config: disabled_screen})
    Repo.insert!(%ScreenConfig{id: "hidden", config: hidden_screen})

    now = System.system_time(:second)

    expect(ScreensByAlert.Mock, :get_screens_last_updated, fn ["eligible"] ->
      %{"eligible" => now}
    end)

    expect(ScreensByAlert.Mock, :get_in_progress, fn _screen_ids -> [] end)
    expect(ScreensByAlert.Mock, :put_in_progress, fn [] -> :ok end)

    assert {:noreply, refreshing_ids} = SelfRefreshRunner.handle_info(:check, MapSet.new())
    assert MapSet.equal?(refreshing_ids, MapSet.new())
  end

  defp restore_app_env(app, key, nil), do: Application.delete_env(app, key)
  defp restore_app_env(app, key, value), do: Application.put_env(app, key, value)
end
