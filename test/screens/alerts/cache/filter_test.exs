defmodule Screens.Alerts.Cache.FilterTest do
  use ExUnit.Case, async: true

  import Mox

  alias Screens.Alerts.Cache.Filter
  alias Screens.Routes.Route

  setup :verify_on_exit!

  describe "build_matchers/1" do
    test "passes through empty filters" do
      assert [] == Filter.build_matchers(%{})
    end

    test "adds matchers for direction_id" do
      assert [%{direction_id: 0}] == Filter.build_matchers(%{direction_id: 0})
      assert [%{direction_id: 1}] == Filter.build_matchers(%{direction_id: 1})
    end

    test "adds matchers for route_types" do
      assert [%{route_type: 1}, %{route_type: 2}] == Filter.build_matchers(%{route_types: [1, 2]})
    end

    test "adds matchers for stops" do
      stub(Route.Mock, :serving_stop, fn _ -> {:ok, []} end)

      assert [
               %{stop: "place-pktrm"},
               %{stop: "place-aport"}
             ] = Filter.build_matchers(%{stops: ["place-pktrm", "place-aport"]})
    end

    test "merges stop matchers into other matchers" do
      stub(Route.Mock, :serving_stop, fn _ -> {:ok, []} end)

      assert [
               %{stop: nil, direction_id: 0},
               %{stop: "place-pktrm", direction_id: 0},
               %{stop: "place-aport", direction_id: 0}
             ] == Filter.build_matchers(%{direction_id: 0, stops: ["place-pktrm", "place-aport"]})
    end

    test "adds matchers for routes at the stops" do
      stub(Route.Mock, :serving_stop, fn
        "place-aport" ->
          {:ok, [%Route{id: "Blue"}, %Route{id: "743"}]}
      end)

      assert [
               %{stop: nil, route: "Blue"},
               %{stop: "place-aport", route: "Blue"},
               %{stop: nil, route: "743"},
               %{stop: "place-aport", route: "743"},
               %{stop: "place-aport"}
             ] == Filter.build_matchers(%{stops: ["place-aport"]})
    end

    test "expands route filters to include route types" do
      stub(Route.Mock, :by_id, fn
        "Blue" -> {:ok, %Route{id: "Blue", type: :subway}}
        "Green-E" -> {:ok, %Route{id: "Green-E", type: :light_rail}}
      end)

      assert [
               %{route: "Blue", route_type: 1},
               %{route: "Green-E", route_type: 0}
             ] = Filter.build_matchers(%{routes: ["Blue", "Green-E"]})
    end
  end
end
