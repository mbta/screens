defmodule Screens.ScreensByAlert.SelfRefreshRunnerTest do
  use ExUnit.Case, async: true

  alias Screens.ScreensByAlert
  alias Screens.ScreensByAlert.SelfRefreshRunner
  alias Screens.V2.ScreenData

  import Mox
  setup :verify_on_exit!

  # NOTE: Screen IDs used in these tests come from `test/fixtures/config.json`

  # Use longer timeout locally where machines may be slower than Github CI
  @receive_timeout if System.get_env("CI") == "true", do: 100, else: 500

  @tag :capture_log
  test "refreshes a batch of the most-outdated screens" do
    now = System.system_time(:second)

    expect(ScreensByAlert.Mock, :get_screens_last_updated, fn _screen_ids ->
      %{"1001" => now - 61, "1002" => now - 62, "1301" => now - 63, "1401" => now - 64}
    end)

    # Only the 2 most-outdated screens should be refreshed, per the batch size in test
    expect(ScreenData.Mock, :get, fn "1401", [update_visible_alerts?: true] -> %{type: :x} end)
    expect(ScreenData.Mock, :get, fn "1301", [update_visible_alerts?: true] -> raise "oops" end)

    screen_ids = MapSet.new(~w[1301 1401])
    assert {:noreply, ^screen_ids} = SelfRefreshRunner.handle_info(:check, MapSet.new())

    assert_receive({:done, "1401"}, @receive_timeout)
    assert_receive({:done, "1301"}, @receive_timeout)
  end

  test "skips refreshing if any refreshes are in progress" do
    screen_ids = MapSet.new(~w[1001])
    assert {:noreply, ^screen_ids} = SelfRefreshRunner.handle_info(:check, screen_ids)
  end

  test "tracks when queued refreshes are completed" do
    screen_ids = MapSet.new(~w[1001 1002])
    new_screen_ids = MapSet.new(~w[1002])

    assert {:noreply, ^new_screen_ids} =
             SelfRefreshRunner.handle_info({:done, "1001"}, screen_ids)
  end
end
