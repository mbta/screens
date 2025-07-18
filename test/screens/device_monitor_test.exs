defmodule Screens.DeviceMonitorTest do
  use ExUnit.Case, async: true

  alias Screens.DeviceMonitor
  alias Screens.DeviceMonitor.{MockVendor, State, Store}

  import Mox
  setup :verify_on_exit!

  setup do
    {:ok, store} = Store.start_link()
    {:ok, nil, version} = Store.get(store)

    state = %State{
      now_fn: fn -> ~U[2025-01-01 12:31:01Z] end,
      store: store,
      vendor_mods: [MockVendor]
    }

    {:ok, %{state: state, store: store, version: version}}
  end

  defp run(state), do: DeviceMonitor.handle_info(:run, state)

  test "calls vendor log functions with the correct time range",
       %{state: state, store: store, version: version} do
    :ok = Store.set(store, ~U[2025-01-01 12:29:02Z], version)

    expect(MockVendor, :log, fn {~U[2025-01-01 12:29:00Z], ~U[2025-01-01 12:31:00Z]} ->
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

  test "does not log again within the previous log interval",
       %{state: state, store: store, version: version} do
    :ok = Store.set(store, ~U[2025-01-01 12:31:03Z], version)

    assert {:noreply, ^state} = run(state)

    refute_receive {:DOWN, _, _, _, _}
  end
end
