defmodule Screens.ScreensByAlertTest do
  @moduledoc false
  use ExUnit.Case
  alias Screens.ScreensByAlert

  setup do
    Application.stop(:screens)

    on_exit(fn ->
      Application.start(:screens)
    end)
  end

  describe "start_link/1" do
    test "returns {:ok, pid} when start_link is called" do
      assert {:ok, pid} = ScreensByAlert.start_link()
      on_exit(fn -> Process.exit(pid, :done) end)
    end
  end

  describe "put_data/2" do
    test "returns :ok" do
      {:ok, pid} = ScreensByAlert.start_link()
      assert :ok = ScreensByAlert.put_data(1, [1])
      on_exit(fn -> Process.exit(pid, :done) end)
    end
  end

  describe "get_screens_by_alert/1" do
    setup do
      {:ok, pid} = ScreensByAlert.start_link()
      ScreensByAlert.put_data(1, [1])
      on_exit(fn -> Process.exit(pid, :done) end)
    end

    test "returns list with data when called before expiration" do
      assert [{1, _}] = ScreensByAlert.get_screens_by_alert(1)
    end

    test "returns empty list when called after expiration" do
      assert [{1, _}] = ScreensByAlert.get_screens_by_alert(1)
      Process.sleep(1001)
      assert [] = ScreensByAlert.get_screens_by_alert(1)
    end
  end

  describe "get_screens_last_updated/1" do
    setup do
      {:ok, pid} = ScreensByAlert.start_link()
      ScreensByAlert.put_data(1, [1])
      on_exit(fn -> Process.exit(pid, :done) end)

      %{last_updated: System.system_time(:second)}
    end

    test "returns when screen was last updated", %{last_updated: last_updated} do
      assert last_updated == ScreensByAlert.get_screens_last_updated(1)
    end

    test "returns nil after expiration", %{last_updated: last_updated} do
      assert last_updated == ScreensByAlert.get_screens_last_updated(1)
      Process.sleep(1001)
      assert is_nil(ScreensByAlert.get_screens_last_updated(1))
    end
  end
end
