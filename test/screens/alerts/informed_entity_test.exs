defmodule Screens.Alerts.InformedEntityTest do
  use ExUnit.Case, async: true

  alias Screens.Alerts.InformedEntity

  import Screens.TestSupport.InformedEntityBuilder

  describe "uniq_by_stop/1" do
    test "returns empty list when given empty list" do
      assert [] == InformedEntity.uniq_by_stop([])
    end

    test "keeps all entities when they have different stop IDs" do
      ie1 = ie(stop_id: "place-sstat")
      ie2 = ie(stop_id: "place-park")
      ie3 = ie(stop_id: "place-dwnxg")

      assert [^ie1, ^ie2, ^ie3] = InformedEntity.uniq_by_stop([ie1, ie2, ie3])
    end

    test "deduplicates entities with the same stop ID, regardless of other attributes" do
      ie1 = ie(stop_id: "place-park", route: "Red", direction_id: 0)
      ie2 = ie(stop_id: "place-park", route: "Green", direction_id: 0)
      ie3 = ie(stop_id: "place-park", route: "Red", direction_id: 1)
      ie4 = ie(stop_id: "place-park", route: "Green", direction_id: 1)

      assert [^ie1] = InformedEntity.uniq_by_stop([ie1, ie2, ie3, ie4])
    end

    test "removes ies with nil stops" do
      ie1 = ie(route: "Red")
      ie2 = ie(route: "Orange")

      assert [] = InformedEntity.uniq_by_stop([ie1, ie2])
    end

    test "deduplicates correctly with interleaved duplicates and nil stops" do
      ie1 = ie(stop_id: "place-park", route: "Red")
      ie2 = ie(stop_id: "place-sstat", route: "Green")
      ie3 = ie(stop_id: "place-park", route: "Green")
      ie4 = ie(stop_id: "place-dwnxg", route: "Blue")
      ie5 = ie(stop_id: "place-park", route: "Silver")
      ie_nil_1 = ie(route: "Red")
      ie_nil_2 = ie(route: "Orange")

      assert [^ie1, ^ie2, ^ie4] =
               InformedEntity.uniq_by_stop([ie1, ie2, ie3, ie_nil_1, ie4, ie5, ie_nil_2])
    end
  end
end
