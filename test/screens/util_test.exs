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
      assert "Alewife, Davis, Porter, and Harvard" === format_name_list_to_string(["Alewife", "Davis", "Porter", "Harvard"])
    end
  end
end