defmodule Screens.V2.ScreenDataTest do
  use ExUnit.Case, async: true

  describe "by_screen_id/1" do
    test "returns ok" do
      assert :ok = Screens.V2.ScreenData.by_screen_id(1)
    end
  end
end
