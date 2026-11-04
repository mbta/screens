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

  test "emits one aggregatable event per cold miss, hit, and stale revalidation", %{
    opts: opts,
    date: date
  } do
    subscribe_to_lookups()
    acquire = fn _, _, _ -> {:ok, [], "modified"} end
    assert {:ok, _} = Store.fetch_dataset(%{}, date, opts ++ [acquire_fn: acquire])
    assert_lookup(:miss, :cold, :ok)

    assert {:ok, _} = Store.fetch_dataset(%{}, date, opts ++ [acquire_fn: acquire])
    assert_lookup(:hit, :fresh, :ok)

    later_opts = Keyword.put(opts, :now, DateTime.add(opts[:now], 31, :minute))

    assert {:ok, _} =
             Store.fetch_dataset(
               %{},
               date,
               later_opts ++ [acquire_fn: fn _, _, "modified" -> :not_modified end]
             )

    assert_lookup(:miss, :stale, :ok)
    refute_receive {:lookup, _, _}
  end

  test "failed acquisition is a miss while lock failure is a separate error", %{
    opts: opts,
    date: date
  } do
    subscribe_to_lookups()
    assert :error = Store.fetch_dataset(%{}, date, opts ++ [acquire_fn: fn _, _, _ -> :error end])
    assert_lookup(:miss, :cold, :error)
    assert :error = Store.fetch_dataset(%{}, date, cache: LockFailureCache)
    assert_lookup(:error, :lock_error, :error)
    refute_receive {:lookup, _, _}
  end

  defp subscribe_to_lookups do
    id = make_ref()
    parent = self()

    :ok =
      :telemetry.attach(
        id,
        [:screens, :schedules, :cache, :lookup],
        &__MODULE__.handle_lookup/4,
        parent
      )

    on_exit(fn -> :telemetry.detach(id) end)
  end

  def handle_lookup(_, measurements, metadata, parent) do
    if self() == parent, do: send(parent, {:lookup, measurements, metadata})
  end

  defp assert_lookup(outcome, state, result) do
    assert_receive {:lookup, %{count: 1, duration: duration}, metadata}
    assert duration >= 0

    assert metadata == %{
             cache: :schedules,
             node: node(),
             outcome: outcome,
             state: state,
             result: result
           }
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
    assert dataset.coverage == %{params: %{stop_ids: ["a", "b"]}, complete?: true}
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

    later = DateTime.add(opts[:now], 31, :minute)
    opts = Keyword.put(opts, :now, later)
    acquire = fn _, _, "modified" -> :not_modified end
    assert {:ok, updated} = Store.fetch_dataset(%{}, date, opts ++ [acquire_fn: acquire])
    assert updated.generation == original.generation
    assert updated.retrieved_at == original.retrieved_at
    assert updated.validated_at == later
  end

  test "failed reload retains previous dataset and remains retryable", %{opts: opts, date: date} do
    assert {:ok, original} =
             Store.fetch_dataset(
               %{},
               date,
               opts ++ [acquire_fn: fn _, _, _ -> {:ok, [], nil} end]
             )

    opts = Keyword.put(opts, :now, DateTime.add(opts[:now], 31, :minute))
    assert :error = Store.fetch_dataset(%{}, date, opts ++ [acquire_fn: fn _, _, _ -> :error end])
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
end
