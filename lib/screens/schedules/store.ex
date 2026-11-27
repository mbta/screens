defmodule Screens.Schedules.Store do
  @moduledoc """
  On-demand parsed schedule cache, isolated from V3 API response bodies.

  Equivalent ID sets share a service-date-scoped acquisition. Different scopes
  remain isolated: partial data is never used to satisfy a broader query.
  Freshness is 1 hour by default. On refresh failure, an unexpired dataset for
  the requested service date can be returned without renewing its lifetime.
  Background refresh is not implemented.
  """

  alias Screens.Routes.Route
  alias Screens.RouteType
  alias Screens.Schedules.{Dataset, Fetch, Schedule}
  alias Screens.Stops.Stop
  alias Screens.Trips.Trip
  alias ScreensConfig.Departures.Mode

  @type params :: %{
          optional(:date) => term(),
          optional(:direction_id) => Trip.direction() | :both,
          optional(:include) => term(),
          optional(:mode) => Mode.t() | nil,
          optional(:route_ids) => [Route.id()],
          optional(:route_type) => [RouteType.t()],
          optional(:sort) => String.t(),
          optional(:stop_ids) => [Stop.id()]
        }
  @type key :: {Date.t(), Dataset.query_params()}
  @type dataset_result :: {:ok, Dataset.t()} | :error
  @type acquisition_result :: {:ok, [Schedule.t()], String.t() | nil} | :not_modified | :error
  @type acquire_fn ::
          (Dataset.query_params(), Date.t(), String.t() | nil -> acquisition_result())
  @type opts :: [
          cache: module(),
          now: DateTime.t(),
          acquire_fn: acquire_fn(),
          freshness_ms: non_neg_integer()
        ]

  @freshness_interval :timer.hours(1)
  @entry_ttl :timer.hours(2)

  defmodule Cache do
    @moduledoc false
    use Nebulex.Cache, otp_app: :screens, adapter: Nebulex.Adapters.Local
  end

  @doc "Canonical key: explicit service date plus request parameters."
  @spec key(params(), Date.t()) :: key()
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

  @spec fetch(params(), Date.t()) :: Schedule.result()
  def fetch(params, date) do
    case fetch_dataset(params, date) do
      {:ok, dataset} -> {:ok, dataset.schedules}
      :error -> :error
    end
  end

  @doc "Returns a dataset, falling back to unexpired same-date data if refresh fails."
  @spec fetch_dataset(params(), Date.t(), opts()) :: dataset_result()
  def fetch_dataset(params, date, opts \\ []) do
    cache = Keyword.get(opts, :cache, Cache)
    # A caller-supplied clock is supported; this is the public API's default.
    # credo:disable-for-next-line Screens.Checks.UntestableDateTime
    now = Keyword.get_lazy(opts, :now, &DateTime.utc_now/0)
    acquire = Keyword.get(opts, :acquire_fn, &Fetch.acquire/3)
    freshness_ms = Keyword.get(opts, :freshness_ms, @freshness_interval)
    key = key(params, date)

    case cache.transaction(
           fn -> load(cache, key, acquire, now, freshness_ms) end,
           keys: [key],
           retries: 50,
           retry_interval: 100
         ) do
      {:ok, result} -> result
      {:error, _} -> :error
    end
  end

  @spec load(module(), key(), acquire_fn(), DateTime.t(), non_neg_integer()) :: dataset_result()
  defp load(cache, {date, params} = key, acquire, now, freshness_ms) do
    previous =
      case cache.fetch(key) do
        {:ok, %Dataset{service_date: ^date} = dataset} -> dataset
        _ -> nil
      end

    if previous && DateTime.diff(now, previous.validated_at, :millisecond) < freshness_ms do
      {:ok, previous}
    else
      validator = if previous, do: previous.last_modified

      result =
        case acquire.(params, date, validator) do
          {:ok, schedules, modified} ->
            dataset = %Dataset{
              schedules: schedules,
              service_date: date,
              query_coverage: %{params: params, complete?: true},
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

      case result do
        :error -> stale_fallback(cache, key, previous)
        success -> success
      end
    end
  end

  @spec stale_fallback(module(), key(), Dataset.t() | nil) :: dataset_result()
  defp stale_fallback(_cache, _key, nil), do: :error

  defp stale_fallback(cache, {date, _params} = key, %Dataset{generation: generation}) do
    case cache.fetch(key) do
      {:ok, %Dataset{service_date: ^date, generation: ^generation} = dataset} -> {:ok, dataset}
      _ -> :error
    end
  end

  @spec publish(module(), key(), Dataset.t()) :: dataset_result()
  defp publish(cache, key, dataset) do
    case cache.put(key, dataset, ttl: @entry_ttl) do
      :ok -> {:ok, dataset}
      {:error, _} -> :error
    end
  end
end
