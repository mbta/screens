defmodule Screens.Schedules.StoreTest do
  use ExUnit.Case, async: true

  alias Screens.Schedules.{Dataset, Schedule, Store}

  defmodule TestCache do
    use Nebulex.Cache, otp_app: :screens, adapter: Nebulex.Adapters.Local
  end

  defmodule LockFailureCache do
    def transaction(_, _), do: {:error, :lock_failed}
  end

  setup do
    start_supervised!(TestCache)
    {:ok, opts: [cache: TestCache, now: ~U[2024-10-11 12:00:00Z]], date: ~D[2024-10-11]}
  end

  test "lock failure returns an error", %{date: date} do
    assert :error = Store.fetch_dataset(%{}, date, cache: LockFailureCache)
  end

  test "canonicalizes equivalent ID sets and date/include overrides", %{date: date} do
    assert Store.key(%{stop_ids: ["b", "a", "a"], date: ~D[2000-01-01], include: []}, date) ==
             Store.key(%{stop_ids: ["a", "b"]}, date)

    unfiltered = %{stop_ids: [], route_ids: [], direction_id: :both, mode: nil}
    assert Store.key(unfiltered, date) == Store.key(%{}, date)

    refute Store.key(%{}, date) == Store.key(%{}, Date.add(date, 1))
  end

  test "loads once, stores parsed metadata and isolates dates and scopes", %{
    opts: opts,
    date: date
  } do
    parent = self()

    acquire = fn params, requested_date, nil ->
      send(parent, {:acquired, params, requested_date})
      {:ok, [%Schedule{id: "schedule"}], "modified"}
    end

    opts = Keyword.put(opts, :acquire_fn, acquire)
    assert {:ok, %Dataset{} = dataset} = Store.fetch_dataset(%{stop_ids: ["b", "a"]}, date, opts)
    assert_receive {:acquired, %{stop_ids: ["a", "b"]}, ^date}
    assert dataset.source_version == nil
    assert dataset.query_coverage == %{params: %{stop_ids: ["a", "b"]}, complete?: true}
    assert {:ok, ^dataset} = Store.fetch_dataset(%{stop_ids: ["a", "b", "b"]}, date, opts)
    refute_receive {:acquired, _, _}
    assert {:ok, _} = Store.fetch_dataset(%{stop_ids: ["a"]}, date, opts)
    assert_receive {:acquired, %{stop_ids: ["a"]}, ^date}
    tomorrow = Date.add(date, 1)
    assert {:ok, _} = Store.fetch_dataset(%{stop_ids: ["a"]}, tomorrow, opts)
    assert_receive {:acquired, _, ^tomorrow}
  end

  test "coalesces concurrent acquisitions", %{opts: opts, date: date} do
    parent = self()

    acquire = fn _, _, _ ->
      send(parent, :acquired)

      receive do
        :release -> {:ok, [], nil}
      end
    end

    opts = Keyword.put(opts, :acquire_fn, acquire)
    first = Task.async(fn -> Store.fetch_dataset(%{}, date, opts) end)
    assert_receive :acquired
    second = Task.async(fn -> Store.fetch_dataset(%{}, date, opts) end)
    send(first.pid, :release)
    assert {:ok, dataset} = Task.await(first)
    assert {:ok, ^dataset} = Task.await(second)
    refute_receive :acquired
  end

  test "revalidation retains generation and retrieval time", %{opts: opts, date: date} do
    assert {:ok, original} =
             Store.fetch_dataset(
               %{},
               date,
               opts ++ [acquire_fn: fn _, _, nil -> {:ok, [], "modified"} end]
             )

    before_boundary = Keyword.put(opts, :now, DateTime.add(opts[:now], 59, :minute))

    assert {:ok, ^original} =
             Store.fetch_dataset(
               %{},
               date,
               before_boundary ++ [acquire_fn: fn _, _, _ -> flunk("unexpected revalidation") end]
             )

    later = DateTime.add(opts[:now], 60, :minute)
    opts = Keyword.put(opts, :now, later)
    acquire = fn _, _, "modified" -> :not_modified end
    assert {:ok, updated} = Store.fetch_dataset(%{}, date, opts ++ [acquire_fn: acquire])
    assert updated.generation == original.generation
    assert updated.retrieved_at == original.retrieved_at
    assert updated.validated_at == later
  end

  test "failed reload returns the retained dataset and remains retryable", %{
    opts: opts,
    date: date
  } do
    assert {:ok, original} =
             Store.fetch_dataset(
               %{},
               date,
               opts ++ [acquire_fn: fn _, _, _ -> {:ok, [], nil} end]
             )

    opts = Keyword.put(opts, :now, DateTime.add(opts[:now], 60, :minute))

    assert {:ok, ^original} =
             Store.fetch_dataset(%{}, date, opts ++ [acquire_fn: fn _, _, _ -> :error end])

    assert {:ok, ^original} = TestCache.fetch(Store.key(%{}, date))

    assert {:ok, replaced} =
             Store.fetch_dataset(
               %{},
               date,
               opts ++ [acquire_fn: fn _, _, _ -> {:ok, [], nil} end]
             )

    refute replaced.generation == original.generation
  end

  test "cold failures are not cached", %{opts: opts, date: date} do
    assert :error = Store.fetch_dataset(%{}, date, opts ++ [acquire_fn: fn _, _, _ -> :error end])
    assert {:error, _} = TestCache.fetch(Store.key(%{}, date))
  end

  test "does not fall back to the prior service day when the new day's load fails", %{
    opts: opts,
    date: date
  } do
    assert {:ok, _} =
             Store.fetch_dataset(
               %{},
               date,
               opts ++ [acquire_fn: fn _, _, _ -> {:ok, [], nil} end]
             )

    assert :error =
             Store.fetch_dataset(
               %{},
               Date.add(date, 1),
               opts ++ [acquire_fn: fn _, _, _ -> :error end]
             )
  end

  test "does not return a different service date after a refresh failure", %{
    opts: opts,
    date: date
  } do
    assert {:ok, original} =
             Store.fetch_dataset(
               %{},
               date,
               opts ++ [acquire_fn: fn _, _, _ -> {:ok, [], nil} end]
             )

    key = Store.key(%{}, date)
    assert :ok = TestCache.put(key, %{original | service_date: Date.add(date, -1)})

    assert :error =
             Store.fetch_dataset(%{}, date, opts ++ [acquire_fn: fn _, _, nil -> :error end])
  end

  test "does not return stale data that expires during refresh", %{opts: opts, date: date} do
    assert {:ok, _} =
             Store.fetch_dataset(
               %{},
               date,
               opts ++ [acquire_fn: fn _, _, _ -> {:ok, [], nil} end]
             )

    later_opts = Keyword.put(opts, :now, DateTime.add(opts[:now], 60, :minute))
    key = Store.key(%{}, date)

    acquire = fn _, _, _ ->
      assert {:ok, true} = TestCache.expire(key, 0)
      :error
    end

    assert :error = Store.fetch_dataset(%{}, date, later_opts ++ [acquire_fn: acquire])
  end

  test "datasets expire two hours after successful publication", %{opts: opts, date: date} do
    acquire = fn _, _, nil -> {:ok, [], "modified"} end
    assert {:ok, _} = Store.fetch_dataset(%{}, date, opts ++ [acquire_fn: acquire])
    key = Store.key(%{}, date)
    assert {:ok, ttl} = TestCache.ttl(key)
    assert ttl > :timer.minutes(119) and ttl <= :timer.hours(2)

    assert {:ok, true} = TestCache.expire(key, 0)
    assert {:error, _} = TestCache.fetch(key)
    assert {:ok, _} = Store.fetch_dataset(%{}, date, opts ++ [acquire_fn: acquire])
  end

  test "only successful revalidation renews the TTL", %{opts: opts, date: date} do
    acquire = fn _, _, nil -> {:ok, [], "modified"} end
    assert {:ok, original} = Store.fetch_dataset(%{}, date, opts ++ [acquire_fn: acquire])
    key = Store.key(%{}, date)
    assert {:ok, true} = TestCache.expire(key, :timer.minutes(10))

    assert {:ok, _} = Store.fetch_dataset(%{}, date, opts ++ [acquire_fn: acquire])
    assert {:ok, ttl} = TestCache.ttl(key)
    assert ttl <= :timer.minutes(10)

    later_opts = Keyword.put(opts, :now, DateTime.add(opts[:now], 60, :minute))
    failure_opts = later_opts ++ [acquire_fn: fn _, _, _ -> :error end]
    assert {:ok, ^original} = Store.fetch_dataset(%{}, date, failure_opts)
    assert {:ok, ttl} = TestCache.ttl(key)
    assert ttl <= :timer.minutes(10)

    assert {:ok, _} =
             Store.fetch_dataset(
               %{},
               date,
               later_opts ++ [acquire_fn: fn _, _, "modified" -> :not_modified end]
             )

    assert {:ok, ttl} = TestCache.ttl(key)
    assert ttl > :timer.minutes(119) and ttl <= :timer.hours(2)
  end
end
