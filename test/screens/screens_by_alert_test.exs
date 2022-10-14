defmodule Screens.ScreensByAlertTest do
  @moduledoc false
  use ExUnit.Case, async: true
  alias Screens.ScreensByAlert

  describe "start_link/1" do
    test "returns {:ok, pid} when start_link is called" do
      Application.stop(:screens)

      on_exit(fn ->
        Application.start(:screens)
      end)

      assert {:ok, _pid} = ScreensByAlert.start_link()
    end
  end

  describe "put_data/2" do
    test "returns :ok" do
      assert :ok = ScreensByAlert.put_data(0, [])
    end
  end

  describe "get_screens_by_alert/1" do
    test "returns []" do
      assert [] = ScreensByAlert.get_screens_by_alert(0)
    end
  end

  describe "get_screens_last_updated/1" do
    test "returns 0" do
      assert 0 = ScreensByAlert.get_screens_last_updated(0)
    end
  end
end
