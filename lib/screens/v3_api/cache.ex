defmodule Screens.V3Api.Cache do
  @moduledoc """
  Cache used to speed up or eliminate HTTP calls to the V3 API.

  Cached API responses are categorized as either "fresh" or "stale". When a response was cached
  recently enough that we think reusing it without checking the API at all is acceptable, it is
  "fresh". Else it is "stale" and we should check before reusing it (using If-Modified-Since).
  """

  defmodule Realtime do
    @moduledoc "Caches data derived from GTFS-RT, which becomes stale very quickly."
    use Nebulex.Cache, otp_app: :screens, adapter: Nebulex.Adapters.Local

    def unconditional_ttl, do: :timer.seconds(3)
  end

  defmodule Static do
    @moduledoc "Caches data derived from static GTFS, which becomes stale relatively slowly."
    use Nebulex.Cache, otp_app: :screens, adapter: Nebulex.Adapters.Local

    def unconditional_ttl, do: :timer.minutes(30)
  end

  @realtime_resources ~w[alert prediction vehicle]

  @type key :: {path :: String.t(), params :: map()}
  @type result :: {:fresh, term()} | {:stale, term()} | nil

  @doc "Get a response from the cache."
  @spec get(key()) :: result()
  @spec get(key(), now :: DateTime.t()) :: result()
  def get(key, now \\ DateTime.utc_now()) do
    case cache_for(key).get(key) do
      {stale_at, value} ->
        if DateTime.before?(now, stale_at), do: {:fresh, value}, else: {:stale, value}

      nil ->
        nil
    end
  end

  @doc "Put a response in the cache."
  @spec put(key(), term()) :: :ok
  @spec put(key(), term(), now :: DateTime.t()) :: :ok
  def put(key, value, now \\ DateTime.utc_now()) do
    cache = cache_for(key)
    stale_at = DateTime.add(now, cache.unconditional_ttl(), :millisecond)
    cache.put(key, {stale_at, value})
  end

  # Imperfectly check whether a request could return any data derived from GTFS-RT, and assign
  # it to the appropriate cache. Should err on the side of over-categorizing data as `Realtime`,
  # since we give static data a very long unconditional TTL.
  defp cache_for({path, params}) do
    if String.contains?(path, @realtime_resources) or
         params |> Map.get("include", "") |> String.contains?(@realtime_resources),
       do: Realtime,
       else: Static
  end
end
