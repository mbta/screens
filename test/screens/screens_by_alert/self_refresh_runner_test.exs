defmodule Screens.ScreensByAlert.SelfRefreshRunnerTest do
  use ExUnit.Case, async: true

  alias Screens.Config.ScreenConfig
  alias Screens.Repo
  alias Screens.ScreensByAlert
  alias Screens.ScreensByAlert.SelfRefreshRunner
  import Mox
  import Screens.TestSupport.ScreenConfigBuilder

  setup :verify_on_exit!

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    :ok
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
  test "uses Postgres-backed eligible screen IDs" do
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

    assert {:noreply, refreshing_ids} = SelfRefreshRunner.handle_info(:check, MapSet.new())
    assert MapSet.equal?(refreshing_ids, MapSet.new())
  end
end
