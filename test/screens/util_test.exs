defmodule Screens.UtilTest do
  use ExUnit.Case, async: true

  import Screens.Util

  describe "format_name_list_to_string/1" do
    test "returns single noun if list has length 1" do
      assert "Alewife" === format_name_list_to_string(["Alewife"])
    end

    test "returns 'X and Y' if list has length 2" do
      assert "Alewife and Davis" === format_name_list_to_string(["Alewife", "Davis"])
    end

    test "returns 'X, Y, and Z' if list has length >= 3" do
      assert "Alewife, Davis, Porter, and Harvard" ===
               format_name_list_to_string(["Alewife", "Davis", "Porter", "Harvard"])
    end
  end

  describe "time_in_range?/1" do
    test "returns false for a time before a normal range" do
      t = ~T[01:00:00]
      start_time = ~T[05:00:00]
      stop_time = ~T[07:00:00]

      refute time_in_range?(t, start_time, stop_time)
    end

    test "returns false for a time after a normal range" do
      t = ~T[09:00:00]
      start_time = ~T[05:00:00]
      stop_time = ~T[07:00:00]

      refute time_in_range?(t, start_time, stop_time)
    end

    test "returns true for a time at start of a normal range" do
      t = ~T[05:00:00]
      start_time = ~T[05:00:00]
      stop_time = ~T[07:00:00]

      assert time_in_range?(t, start_time, stop_time)
    end

    test "returns false for a time at end of a normal range" do
      t = ~T[07:00:00]
      start_time = ~T[05:00:00]
      stop_time = ~T[07:00:00]

      refute time_in_range?(t, start_time, stop_time)
    end

    test "returns true for a time within a normal range" do
      t = ~T[06:00:00]
      start_time = ~T[05:00:00]
      stop_time = ~T[07:00:00]

      assert time_in_range?(t, start_time, stop_time)
    end

    #############################

    test "returns false for a time outside an inverted range" do
      t = ~T[06:00:00]
      start_time = ~T[07:00:00]
      stop_time = ~T[05:00:00]

      refute time_in_range?(t, start_time, stop_time)
    end

    test "returns true for a time at start of an inverted range" do
      t = ~T[07:00:00]
      start_time = ~T[07:00:00]
      stop_time = ~T[05:00:00]

      assert time_in_range?(t, start_time, stop_time)
    end

    test "returns false for a time at end of an inverted range" do
      t = ~T[05:00:00]
      start_time = ~T[07:00:00]
      stop_time = ~T[05:00:00]

      refute time_in_range?(t, start_time, stop_time)
    end

    test "returns true for a time within an inverted range (after start/before midnight)" do
      t = ~T[08:00:00]
      start_time = ~T[07:00:00]
      stop_time = ~T[05:00:00]

      assert time_in_range?(t, start_time, stop_time)
    end

    test "returns true for a time within an inverted range (before end/after midnight)" do
      t = ~T[04:00:00]
      start_time = ~T[07:00:00]
      stop_time = ~T[05:00:00]

      assert time_in_range?(t, start_time, stop_time)
    end
  end
end
