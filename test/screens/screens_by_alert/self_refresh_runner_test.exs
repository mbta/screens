defmodule Screens.ScreensByAlert.SelfRefreshRunnerTest do
  use ExUnit.Case, async: true

  alias Screens.ScreensByAlert
  alias Screens.ScreensByAlert.SelfRefreshRunner
  alias Screens.V2.ScreenData
  alias ScreensConfig.Screen

  import Mox
  setup :verify_on_exit!

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

    expect(ScreenData.Mock, :get, fn %Screen{app_id: :bus_shelter_v2},
                                     [update_visible_alerts_for_screen_id: "1401"] ->
      %{type: :x}
    end)

    expect(ScreenData.Mock, :get, fn %Screen{app_id: :bus_eink_v2},
                                     [update_visible_alerts_for_screen_id: "1002"] ->
      raise "oops"
    end)

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
end
