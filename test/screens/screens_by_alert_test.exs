defmodule Screens.ScreensByAlertTest do
  @moduledoc false
  use ExUnit.Case
  alias Screens.ScreensByAlert

  @tag :skip
  describe "get_screens_by_alert/1" do
    setup do
      ScreensByAlert.put_data(1, [1])
      on_exit(fn -> ScreensByAlert.put_data(1, []) end)

      %{
        screens_by_alert_ttl:
          Application.get_env(:screens, :screens_by_alert)[:screens_by_alert_ttl_seconds],
        screens_ttl: Application.get_env(:screens, :screens_by_alert)[:screens_ttl_seconds]
      }
    end

    @tag :skip
    test "returns map with data when called before expiration" do
      assert %{1 => [1]} == ScreensByAlert.get_screens_by_alert([1])
    end

    @tag :skip
    test "returns map with default empty list when called after expiration", %{
      screens_by_alert_ttl: ttl
    } do
      assert %{1 => [1]} == ScreensByAlert.get_screens_by_alert([1])
      Process.sleep((ttl + 1) * 1000)
      assert %{1 => []} == ScreensByAlert.get_screens_by_alert([1])
    end

    @tag :skip
    test "returns map with no expired", %{screens_ttl: ttl} do
      assert %{1 => [1]} == ScreensByAlert.get_screens_by_alert([1])
      Process.sleep(ttl * 1000)
      assert :ok = ScreensByAlert.put_data(2, [1])
      assert %{1 => [2]} == ScreensByAlert.get_screens_by_alert([1])
    end
  end

  describe "get_screens_last_updated/1" do
    setup do
      ScreensByAlert.put_data(1, [1])
      on_exit(fn -> ScreensByAlert.put_data(1, []) end)

      %{
        last_updated: System.system_time(:second),
        ttl: Application.get_env(:screens, :screens_by_alert)[:screens_last_updated_ttl_seconds]
      }
    end

    @tag :skip
    test "returns when screen was last updated", %{last_updated: last_updated} do
      assert %{1 => last_updated} == ScreensByAlert.get_screens_last_updated([1])
    end

    @tag :skip
    test "returns map with default timestamp of 0 after expiration", %{
      last_updated: last_updated,
      ttl: ttl
    } do
      assert %{1 => last_updated} == ScreensByAlert.get_screens_last_updated([1])
      Process.sleep((ttl + 1) * 1000)
      assert %{1 => 0} == ScreensByAlert.get_screens_last_updated([1])
    end
  end
end
