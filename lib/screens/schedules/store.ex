defmodule Screens.Schedules.Store do
  @moduledoc """
  On-demand parsed schedule cache, isolated from V3 API response bodies.

  Equivalent ID sets share a service-date-scoped acquisition. Different scopes
  remain isolated: partial data is never used to satisfy a broader query.
  Freshness is 30 minutes by default. Failed revalidation retains the old entry
  but returns an error; stale serving and background refresh are separate work.
  """

  alias Screens.Schedules.{Dataset, Fetch}

  defmodule Cache do
    @moduledoc false
    use Nebulex.Cache, otp_app: :screens, adapter: Nebulex.Adapters.Local
  end

  @doc "Canonical key: explicit service date plus request parameters."
  def key(params, %Date{} = service_date) do
    params =
      params
      |> Map.drop([:date, :include])
      |> Enum.reject(fn {key, value} ->
        {key, value} in [{:stop_ids, []}, {:route_ids, []}, {:direction_id, :both}, {:mode, nil}]
      end)
      |> Map.new(fn
        {key, ids} when key in [:stop_ids, :route_ids, :route_type] and is_list(ids) ->
          {key, Enum.sort(Enum.uniq(ids))}

        pair ->
          pair
      end)

    {service_date, params}
  end

  @spec fetch(map(), Date.t()) :: Screens.Schedules.Schedule.result()
  def fetch(params, date) do
    case fetch_dataset(params, date) do
      {:ok, dataset} -> {:ok, dataset.schedules}
      :error -> :error
    end
  end

  @doc "Returns a complete, fresh dataset; synchronously loads or revalidates on demand."
  def fetch_dataset(params, date, opts \\ []) do
    cache = Keyword.get(opts, :cache, Cache)
    # A caller-supplied clock is supported; this is the public API's default.
    # credo:disable-for-next-line Screens.Checks.UntestableDateTime
    now = Keyword.get_lazy(opts, :now, &DateTime.utc_now/0)
    acquire = Keyword.get(opts, :acquire_fn, &Fetch.acquire/3)
    freshness_ms = Keyword.get(opts, :freshness_ms, :timer.minutes(30))
    {date, params} = key(params, date)
    key = {date, params}
    started_at = System.monotonic_time()

    {result, outcome, state} =
      case cache.transaction(
             fn -> load(cache, key, acquire, now, freshness_ms) end,
             keys: [key],
             retries: 50,
             retry_interval: 100
           ) do
        {:ok, lookup} -> lookup
        {:error, _} -> {:error, :error, :lock_error}
      end

    :telemetry.execute(
      [:screens, :schedules, :cache, :lookup],
      %{count: 1, duration: System.monotonic_time() - started_at},
      %{
        cache: :schedules,
        node: node(),
        outcome: outcome,
        state: state,
        result: if(result == :error, do: :error, else: :ok)
      }
    )

    result
  end

  defp load(cache, {date, params} = key, acquire, now, freshness_ms) do
    previous =
      case cache.fetch(key) do
        {:ok, dataset} -> dataset
        {:error, _} -> nil
      end

    if previous && DateTime.diff(now, previous.validated_at, :millisecond) < freshness_ms do
      {{:ok, previous}, :hit, :fresh}
    else
      validator = if previous, do: previous.last_modified

      result =
        case acquire.(params, date, validator) do
          {:ok, schedules, modified} ->
            dataset = %Dataset{
              schedules: schedules,
              service_date: date,
              coverage: %{params: params, complete?: true},
              generation: make_ref(),
              retrieved_at: now,
              validated_at: now,
              last_modified: modified
            }

            publish(cache, key, dataset)

          :not_modified when not is_nil(previous) and not is_nil(validator) ->
            publish(cache, key, %{previous | validated_at: now})

          _ ->
            :error
        end

      {result, :miss, if(previous, do: :stale, else: :cold)}
    end
  end

  defp publish(cache, key, dataset) do
    case cache.put(key, dataset) do
      :ok -> {:ok, dataset}
      {:error, _} -> :error
    end
  end
end
