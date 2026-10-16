defmodule Screens.V2.ScreenData.Cache do
  @moduledoc """
  Distributed partitioned cache that stores the set of widgets generated for a given screen ID.

  Each node in the cluster "owns" a subset of screen IDs and is exclusively responsible for
  generating the corresponding widgets. When a node gets a request for a screen ID it doesn't
  own, it RPCs the request to the node that does. The main motivation for doing this versus a
  non-partitioned distributed cache is to distribute the memory load of the V3 API cache across
  the cluster, so not every node has to cache the data required to serve every screen.
  """

  defmodule Store do
    @moduledoc """
    Provides a layer of indirection over the Nebulex adapter, allowing it to be mocked in tests.
    `Nebulex.Cache` can't be used directly as the mock interface due to missing callback defs for
    some arities and lacking adapter-specific functions like `Partitioned.find_node/1`.
    """

    @behaviour __MODULE__

    @type key :: String.t()
    @type value :: [Screens.V2.WidgetInstance.t()]

    @type error :: {:error, Nebulex.Error.t()}

    @callback call(node(), module(), atom(), [any()], timeout()) :: {:ok, any()} | {:error, any()}
    @callback delete_all(Nebulex.Cache.query_spec()) :: {:ok, non_neg_integer()} | error()
    @callback fetch(key()) :: {:ok, value()} | error()
    @callback find_node(key()) :: {:ok, node()} | error()
    @callback put(key(), value(), keyword()) :: :ok | error()
    @callback transaction((-> result), keyword()) :: {:ok, result} | error() when result: any()

    defmodule Adapter do
      @moduledoc false
      use Nebulex.Cache, otp_app: :screens, adapter: Nebulex.Adapters.Partitioned
    end

    defdelegate delete_all(query), to: Adapter
    defdelegate fetch(key), to: Adapter
    defdelegate find_node(key), to: Adapter
    defdelegate put(key, value, opts \\ []), to: Adapter
    defdelegate transaction(fun, opts \\ []), to: Adapter

    @doc "Wrapper for `:erpc.call/5` that returns an `:ok`/`:error` tuple instead of raising."
    def call(node, mod, fun, args, timeout) do
      {:ok, :erpc.call(node, mod, fun, args, timeout)}
    rescue
      e in ErlangError -> {:error, e.original}
    end
  end

  defmodule Meta do
    @moduledoc "Metadata returned about the internal cache operations."
    @type t :: %__MODULE__{
            what: :hit | :miss | {:error, operation :: atom(), Nebulex.Error.t() | nil},
            where: :local | :remote,
            ttl: seconds :: pos_integer()
          }
    defstruct what: :miss, where: :local, ttl: 1
  end

  alias Screens.V2.CandidateGenerator.Timeout
  alias ScreensConfig.Screen

  import Screens.Inject
  @parameters injected(Screens.V2.ScreenData.Parameters)
  @store injected(Store)

  @doc """
  Clear the cache for the given screens, running a supplied function in a transaction that locks
  the given screen IDs, enabling consistency for operations that change screen configs. The cache
  delete is also part of this transaction, and if it fails, the function is not called.
  """
  @callback invalidate([Store.key()]) :: {:ok, nil} | Store.error()
  @callback invalidate([Store.key()], (-> res)) :: {:ok, res} | Store.error() when res: any()
  def invalidate(keys, func \\ fn -> nil end) do
    @store.transaction(
      fn -> with {:ok, _count} <- @store.delete_all(in: keys), do: func.() end,
      keys: keys
    )
  end

  @type options :: [now_fn: (-> DateTime.t())]

  @doc """
  Fetch or generate the widgets for a given screen.

  This function is "fail-safe" and simply generates widgets on the local node in the event of any
  error interacting with the cache; the returned `Meta` indicates whether this happened.
  """
  @spec instances(Store.key(), Screen.t(), options()) :: {Store.value(), Meta.t()}
  def instances(id, screen, opts \\ []) do
    case @store.find_node(id) do
      {:ok, n} when n == node() ->
        # This node probably* owns the key. Fetch it or generate and populate it, locking the key
        # to avoid doing duplicate work.
        #
        # (* There's no guarantee this hasn't changed since we called `find_node`. This still
        # works if it has, since the lock is cluster-wide and the actual cache operations will
        # always use the current owner.)
        case @store.transaction(fn -> fetch_or_generate(id, screen, opts) end, keys: [id]) do
          {:ok, result} -> result
          {:error, error} -> generate(id, screen, opts, {:error, :transaction, error})
        end

      {:ok, node} ->
        # Another node owns the key; proxy the request to it. The timeout should be sufficient to
        # wait for the longest possible candidate generation timeout; if we do exceed this, crash
        # instead of retrying the generation ourself, since the app may be overloaded and at that
        # point the client has been waiting on us for a long time.
        case @store.call(node, __MODULE__, :instances, [id, screen, opts], 20_000) do
          {:ok, {instances, %Meta{} = meta}} ->
            {instances, %Meta{meta | where: :remote}}

          # If unable to reach the remote node, generating instances locally might still work.
          {:error, {:erpc, :noconnection}} ->
            generate(id, screen, opts, {:error, :rpc_connect, nil})

          {:error, {:erpc, :timeout}} ->
            raise Timeout

          {:error, {:exception, Timeout, stacktrace}} ->
            reraise Timeout, stacktrace
        end

      {:error, error} ->
        generate(id, screen, opts, {:error, :find_node, error})
    end
  end

  defp fetch_or_generate(id, screen, opts) do
    case @store.fetch(id) do
      {:ok, instances} ->
        {instances, %Meta{what: :hit, ttl: seconds_until_refresh(id, screen, opts)}}

      {:error, %Nebulex.KeyError{}} ->
        {instances, %Meta{ttl: ttl} = meta} = generate(id, screen, opts, :miss)

        # `ttl` is relative to "now", which might be some milliseconds after the "now" we used
        # when we determined what it should be. Set the TTL a fraction of a second "early" to
        # head off any inconsistencies this might cause. (If we are running this code then we are
        # normally the node that owns the screen, so network RTT on the `put` is not a factor.)
        case @store.put(id, instances, ttl: ttl * 1_000 - 500) do
          :ok -> {instances, meta}
          {:error, error} -> {instances, %Meta{meta | what: {:error, :put, error}}}
        end

      {:error, error} ->
        generate(id, screen, opts, {:error, :fetch, error})
    end
  end

  defp generate(id, screen, opts, meta_what) do
    instances = @parameters.candidate_generator(screen).candidate_instances(screen)
    {instances, %Meta{what: meta_what, ttl: seconds_until_refresh(id, screen, opts)}}
  end

  defp seconds_until_refresh(id, %Screen{app_id: app_id}, opts) do
    # This is testable (and tested), the check just can't pick it up
    # credo:disable-for-next-line Screens.Checks.UntestableDateTime
    now_fn = Keyword.get(opts, :now_fn, &DateTime.utc_now/0)
    @parameters.seconds_until_refresh(id, app_id, now_fn.())
  end
end
