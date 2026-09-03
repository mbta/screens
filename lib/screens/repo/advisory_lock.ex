defmodule Screens.Repo.AdvisoryLock do
  @moduledoc """
  Runs a function while holding a Postgres session-level advisory lock, so that work scheduled on
  every app instance only runs on one of them at a time.

  Can be reused for any recurring cron job type functions that only needs to run once across all tasks.
  New uses of this locking mechanism just need to pass an application-wide unique cron_lock_key
  and an interval for how frequently the job should run.
  """

  import Screens.Inject

  alias Screens.Repo

  @sleeper injected(Screens.Repo.AdvisoryLock.Sleeper)

  @doc """
  Runs `func` if the lock identified by `cron_lock_key` can be acquired immediately, returning `:locked` otherwise.
  `cron_lock_key` must be a unique-per-job 64-bit integer. The lock is held for `interval` ms
  regardless of how quickly `func` completes, so that another instance can't acquire it early.
  """
  @spec with_lock(integer(), non_neg_integer(), (-> result)) :: result
        when result: term()
  def with_lock(cron_lock_key, interval, func) do
    Repo.transact(
      fn ->
        started_at = System.monotonic_time(:millisecond)

        case Repo.query!("SELECT pg_try_advisory_xact_lock($1)", [cron_lock_key]) do
          %{rows: [[true]]} ->
            result = func.()
            hold_lock_until(started_at, interval)
            result

          %{rows: [[false]]} ->
            {:ok, :locked}
        end
      end,
      timeout: interval
    )
  end

  defp hold_lock_until(started_at, interval) do
    # Ensure the lock is held for the full interval. It's released when the transaction ends.
    remaining = interval - (System.monotonic_time(:millisecond) - started_at)
    if remaining > 0, do: @sleeper.sleep(remaining)
  end
end
