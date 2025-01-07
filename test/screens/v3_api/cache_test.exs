defmodule Screens.V3Api.CacheTest do
  use ExUnit.Case, async: true

  alias Screens.V3Api.Cache

  setup do
    # Since these use the real cache, add a unique value to each test's parameters to avoid
    # collisions with other tests.
    {:ok, now: DateTime.utc_now(), params: %{_unique: inspect(make_ref())}}
  end

  defp put_and_get_after(key, value, now, amount, unit) do
    Cache.put(key, value, now)
    Cache.get(key, DateTime.add(now, amount, unit))
  end

  test "gets nil for nonexistent keys", %{params: params} do
    assert Cache.get({"routes", params}) == nil
  end

  test "uses path and params as the cache key", %{params: params} do
    params1 = Map.put(params, :x, 1)
    params2 = Map.put(params, :x, 2)
    Cache.put({"one", params1}, "valA")
    Cache.put({"one", params2}, "valB")
    Cache.put({"two", params1}, "valC")
    Cache.put({"two", params2}, "valD")

    assert {_, "valA"} = Cache.get({"one", params1})
    assert {_, "valB"} = Cache.get({"one", params2})
    assert {_, "valC"} = Cache.get({"two", params1})
    assert {_, "valD"} = Cache.get({"two", params2})
  end

  test "gets fresh static data", %{now: now, params: params} do
    assert {:fresh, "fs1"} = put_and_get_after({"routes", params}, "fs1", now, 15, :minute)
  end

  test "gets fresh realtime data", %{now: now, params: params} do
    assert {:fresh, "fr1"} = put_and_get_after({"alerts", params}, "fr1", now, 2, :second)
  end

  test "gets stale static data", %{now: now, params: params} do
    assert {:stale, "ss1"} = put_and_get_after({"routes", params}, "ss1", now, 2, :hour)
  end

  test "gets stale realtime data", %{now: now, params: params} do
    assert {:stale, "sr1"} = put_and_get_after({"alerts", params}, "sr1", now, 10, :second)
  end

  test "determines cache based on include param", %{now: now, params: params} do
    assert {:fresh, "resp1"} = put_and_get_after({"trips", params}, "resp1", now, 10, :second)

    rt_params = Map.put(params, "include", "shape,predictions,route_pattern.route")
    assert {:stale, "resp2"} = put_and_get_after({"trips", rt_params}, "resp2", now, 10, :second)
  end
end
