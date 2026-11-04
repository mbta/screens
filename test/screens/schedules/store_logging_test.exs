defmodule Screens.Schedules.StoreLoggingTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog

  alias Screens.Schedules.Store

  test "logs lookup outcomes through the application's telemetry handler" do
    previous_level = Logger.level()
    Logger.configure(level: :info)
    on_exit(fn -> Logger.configure(level: previous_level) end)

    params = %{stop_ids: [inspect(make_ref())]}
    date = ~D[2024-10-11]
    on_exit(fn -> Store.Cache.delete(Store.key(params, date)) end)

    log =
      capture_log([level: :info], fn ->
        assert {:ok, _} =
                 Store.fetch_dataset(params, date, acquire_fn: fn _, _, _ -> {:ok, [], nil} end)

        assert {:ok, _} = Store.fetch_dataset(params, date)
      end)

    assert length(Regex.scan(~r/event=screens\.schedules\.cache\.lookup/, log)) == 2
    assert log =~ "outcome=miss"
    assert log =~ "state=cold"
    assert log =~ "outcome=hit"
    assert log =~ "state=fresh"
    assert log =~ "result=ok"
    assert log =~ "count=1"
    assert log =~ "duration="
    refute log =~ hd(params.stop_ids)
  end

  test "configures the requested independent cache budgets" do
    assert Application.fetch_env!(:screens, Screens.V3Api.Cache.Static)[:allocated_memory] ==
             150 * 1024 * 1024

    assert Application.fetch_env!(:screens, Store.Cache)[:allocated_memory] == 450 * 1024 * 1024
  end
end
