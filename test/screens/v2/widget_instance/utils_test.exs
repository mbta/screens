defmodule Screens.V2.WidgetInstance.UtilsTest do
  use ExUnit.Case

  alias Screens.V2.WidgetInstance.Utils
  alias ScreensConfig.Schedule

  describe "in_schedule_windows?/2" do
    setup do
      %{now: ~U[2026-07-01 00:00:00Z]}
    end

    test "returns false for an empty list", %{now: now} do
      refute Utils.in_schedule_windows?([], now)
    end

    test "returns true for a list with nil start and end times", %{now: now} do
      assert Utils.in_schedule_windows?([%Schedule{start_dt: nil, end_dt: nil}], now)
    end

    test "returns true for a list with a start time prior to the current time", %{now: now} do
      assert Utils.in_schedule_windows?(
               [%Schedule{start_dt: DateTime.add(now, -1), end_dt: nil}],
               now
             )
    end

    test "returns true for a list with a start time equal to the current time", %{now: now} do
      assert Utils.in_schedule_windows?(
               [%Schedule{start_dt: now, end_dt: nil}],
               now
             )
    end

    test "returns false for a list with a start time after to the current time", %{now: now} do
      refute Utils.in_schedule_windows?(
               [%Schedule{start_dt: DateTime.add(now, 1), end_dt: nil}],
               now
             )
    end

    test "returns false for a list with an end time equal to the current time", %{now: now} do
      refute Utils.in_schedule_windows?(
               [%Schedule{start_dt: nil, end_dt: now}],
               now
             )
    end

    test "returns true for a list with an end time after the current time", %{now: now} do
      assert Utils.in_schedule_windows?(
               [%Schedule{start_dt: nil, end_dt: DateTime.add(now, 1)}],
               now
             )
    end

    test "returns false for a list with an end time before to the current time", %{now: now} do
      refute Utils.in_schedule_windows?(
               [%Schedule{start_dt: nil, end_dt: DateTime.add(now, -1)}],
               now
             )
    end

    test "returns true for a list with a start and end time in between the current time", %{
      now: now
    } do
      assert Utils.in_schedule_windows?(
               [%Schedule{start_dt: DateTime.add(now, -1), end_dt: DateTime.add(now, 1)}],
               now
             )
    end

    test "returns false for a list with a start before now but an end time equal to the current time",
         %{
           now: now
         } do
      refute Utils.in_schedule_windows?(
               [%Schedule{start_dt: DateTime.add(now, -1), end_dt: now}],
               now
             )
    end

    test "returns false when no schedule with start and end times applies", %{now: now} do
      refute Utils.in_schedule_windows?(
               [
                 %Schedule{start_dt: DateTime.add(now, -2), end_dt: DateTime.add(now, -1)},
                 %Schedule{start_dt: nil, end_dt: now},
                 %Schedule{start_dt: DateTime.add(now, -1), end_dt: now},
                 %Schedule{start_dt: DateTime.add(now, 1), end_dt: DateTime.add(now, 2)}
               ],
               now
             )
    end

    test "considers all schedules in the provided list", %{now: now} do
      assert Utils.in_schedule_windows?(
               [
                 %Schedule{start_dt: DateTime.add(now, -2), end_dt: DateTime.add(now, -1)},
                 %Schedule{start_dt: DateTime.add(now, 1), end_dt: DateTime.add(now, 2)},
                 %Schedule{start_dt: DateTime.add(now, -1), end_dt: nil}
               ],
               now
             )
    end
  end
end
