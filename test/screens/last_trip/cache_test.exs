defmodule Screens.LastTrip.CacheTest do
  use ExUnit.Case, async: true

  alias Screens.LastTrip.Cache

  describe "merge_and_expire_departures/2" do
    test "merges departures, keeping only the latest and most recent for each trip" do
      existing_departures = [{"trip-1", 1}, {"trip-2", 4}]
      departures = [{"trip-2", 2}, {"trip-2", 3}, {"trip-3", 2}]
      expiration = 0

      assert [{"trip-1", 1}, {"trip-2", 3}, {"trip-3", 2}] ==
               Cache.merge_and_expire_departures(existing_departures, departures, expiration)
    end

    test "removes departures that are older than the expiration" do
      existing_departures = [{"trip-1", 1}, {"trip-2", 4}]
      departures = [{"trip-2", 2}, {"trip-2", 3}, {"trip-3", 2}]
      expiration = 1

      assert [{"trip-2", 3}, {"trip-3", 2}] ==
               Cache.merge_and_expire_departures(existing_departures, departures, expiration)
    end
  end
end
