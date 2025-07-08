defmodule Screens.DeviceMonitorTest do
  use ExUnit.Case, async: true

  alias Screens.DeviceMonitor
  alias Screens.DeviceMonitor.{MockVendor, State, Store}

  import Mox
  setup :verify_on_exit!

  setup do
    {:ok, store} = Store.start_link()

    state = %State{
      now_fn: fn -> ~U[2025-01-01 12:02:01Z] end,
      store: store,
      vendor_mods: [MockVendor]
    }

    {:ok, %{state: state, store: store}}
  end

  defp run(state), do: DeviceMonitor.handle_info(:run, state)

  test "calls vendor log functions with the correct time range", %{state: state, store: store} do
    {:ok, nil} = Store.get_and_update(store, ~U[2025-01-01 12:00:02Z])

    expect(MockVendor, :log, fn {~U[2025-01-01 12:00:00Z], ~U[2025-01-01 12:02:00Z]} ->
      :mock_log_done
    end)

    assert {:noreply, ^state} = run(state)
    assert_receive {_ref, :mock_log_done}
    assert_receive {:DOWN, _, _, _, _}
  end

  test "does not log when there is no previous log time", %{state: state} do
    assert {:noreply, ^state} = run(state)

    # assert that no task was started, since otherwise we'd get this message when it completed
    refute_receive {:DOWN, _, _, _, _}
  end

  test "does not log within the same minute as the previous log", %{state: state, store: store} do
    {:ok, nil} = Store.get_and_update(store, ~U[2025-01-01 12:02:00Z])

    assert {:noreply, ^state} = run(state)

    refute_receive {:DOWN, _, _, _, _}
  end
end
