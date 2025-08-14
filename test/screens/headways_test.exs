defmodule Screens.HeadwaysTest do
  use ExUnit.Case, async: true

  alias Screens.Headways

  # Headway values used in assertions come from: test/fixtures/signs_ui_config.json

  @monday ~D[2024-11-04]
  @zone "America/New_York"

  defp local_dt(day_of_week \\ 1, hour \\ 12) do
    # Note the default of Monday at 12:00 is in the `off_peak` period
    @monday |> Date.add(day_of_week - 1) |> DateTime.new!(Time.new!(hour, 0, 0), @zone)
  end

  describe "get/2" do
    @blue_trunk "70042"
    @green_d "70160"
    @red_ashmont "70088"
    @sl_one_terminal_a "17092"
    @sl_two_drydock_ave "31259"
    @sl_three_airport "7096"
    @congress_st_at_wtc "17096"

    test "returns nil for a stop with no defined headways" do
      assert Headways.get("nonexistent", local_dt()) == nil
    end

    test "returns nil for a parent station" do
      assert Headways.get("place-north", local_dt()) == nil
    end

    test "returns the correct value for a given stop" do
      assert Headways.get(@blue_trunk, local_dt()) == {9, 13}
      assert Headways.get(@green_d, local_dt()) == {7, 13}
      assert Headways.get(@red_ashmont, local_dt()) == {24, 32}
      assert Headways.get(@sl_one_terminal_a, local_dt()) == {1, 3}
      assert Headways.get(@sl_two_drydock_ave, local_dt()) == {1, 3}
      assert Headways.get(@sl_three_airport, local_dt()) == {7, 9}
    end

    test "returns the correct value for a given time period" do
      assert Headways.get(@blue_trunk, local_dt(1, 8)) == {5, 7}
      assert Headways.get(@blue_trunk, local_dt(1, 17)) == {5, 7}
      assert Headways.get(@blue_trunk, local_dt(6)) == {10, 14}
      assert Headways.get(@blue_trunk, local_dt(7)) == {12, 16}
    end
  end

  describe "get_with_route/3" do
    test "returns the correct value for a combination of parent station and route for Rail" do
      assert Headways.get_with_route("place-aport", "Blue", local_dt()) == {9, 13}
      assert Headways.get_with_route("place-north", "Green-D", local_dt()) == {7, 13}
      assert Headways.get_with_route("place-north", "Orange", local_dt()) == {9, 11}
    end

    test "returns the correct value for a combination of station id and route for the Silver Line" do
      assert Headways.get_with_route("place-chels", "743", local_dt()) == {7, 9}
      assert Headways.get_with_route("place-crtst", "746", local_dt()) == {1, 3}
      assert Headways.get_with_route("place-crtst", "743", local_dt()) == {1, 3}
      assert Headways.get_with_route(@congress_st_at_wtc, "742", local_dt()) == {1, 3}
      assert Headways.get_with_route(@congress_st_at_wtc, "743", local_dt()) == {1, 3}
      assert Headways.get_with_route("place-crtst", "751", local_dt()) == nil
    end
  end
end
