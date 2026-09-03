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

    @typep error :: {:error, Nebulex.Error.t()}

    @callback call(node(), module(), atom(), [any()], timeout()) :: any()
    @callback fetch(key()) :: {:ok, value()} | error()
    @callback find_node(key()) :: {:ok, node()} | error()
    @callback put(key(), value(), keyword()) :: :ok | error()
    @callback transaction((-> result), keyword()) :: {:ok, result} | error() when result: any()

    defmodule Adapter do
      @moduledoc false
      use Nebulex.Cache, otp_app: :screens, adapter: Nebulex.Adapters.Partitioned
    end

    defdelegate call(node, mod, fun, args, timeout), to: Nebulex.Distributed.RPC
    defdelegate fetch(key), to: Adapter
    defdelegate find_node(key), to: Adapter
    defdelegate put(key, value, opts \\ []), to: Adapter
    defdelegate transaction(fun, opts \\ []), to: Adapter
  end

  defmodule Meta do
    @moduledoc "Metadata returned about the internal cache operations."
    @type t :: %__MODULE__{
            what: :hit | :miss | :refresh | {:error, operation :: atom(), Nebulex.Error.t()},
            where: :local | :remote
          }
    @enforce_keys [:what]
    defstruct what: nil, where: :local
  end

  alias Screens.V2.CandidateGenerator.Timeout
  alias ScreensConfig.Screen

  import Screens.Inject
  @parameters injected(Screens.V2.ScreenData.Parameters)
  @store injected(Store)

  @type options :: [refresh?: boolean()]

  @doc """
  Fetch or generate the widgets for a given screen.

  This function is "fail-safe" and simply generates widgets on the local node in the event of any
  error interacting with the cache; the returned `Meta` indicates whether this happened.

  ### Options

  - `refresh?`: If true, ignores any cached data and always generates widgets fresh. The result
    may still be stored in the cache.
  """
  @spec instances(Store.key(), Screen.t()) :: {Store.value(), Meta.t()}
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
          {:error, error} -> {generate(screen), %Meta{what: {:error, :transaction, error}}}
        end

      {:ok, node} ->
        # Another node owns the key; proxy the request to it. The timeout should be sufficient to
        # wait for the longest possible candidate generation timeout; if we do exceed this, crash
        # instead of retrying the generation ourself, since the app may be overloaded and at that
        # point the client has been waiting on us for a long time.
        case @store.call(node, __MODULE__, :instances, [id, screen, opts], 20_000) do
          {:error, %Nebulex.Error{reason: {:rpc, {:error, :timeout}}}} -> raise Timeout
          {:error, e} -> {generate(screen), %Meta{what: {:error, :rpc, e}, where: :remote}}
          {instances, %Meta{} = meta} -> {instances, %Meta{meta | where: :remote}}
        end

      {:error, error} ->
        {generate(screen), %Meta{what: {:error, :find_node, error}}}
    end
  end

  defp fetch_or_generate(id, screen, opts) do
    case maybe_fetch(id, opts) do
      {:ok, instances} ->
        {instances, %Meta{what: :hit}}

      result when result in [:miss, :refresh] ->
        instances = generate(screen)

        # For now we cache instances just long enough to avoid duplicating work for other
        # near-simultaneous requests (e.g. the two sides of a duo unit). This is important to
        # preserve the timeliness of displayed information, since refresh cycles running on
        # screen clients are not yet aware they may be receiving cached data. The next phase of
        # work will address this and enable instances to be cached for longer, up to the full
        # length of a refresh cycle.
        case @store.put(id, instances, ttl: :timer.seconds(5)) do
          :ok -> {instances, %Meta{what: result}}
          {:error, error} -> {instances, %Meta{what: {:error, :put, error}}}
        end

      {:error, error} ->
        {generate(screen), %Meta{what: {:error, :fetch, error}}}
    end
  end

  defp generate(screen), do: @parameters.candidate_generator(screen).candidate_instances(screen)

  defp maybe_fetch(id, opts) do
    if Keyword.get(opts, :refresh?, false),
      do: :refresh,
      else: with({:error, %Nebulex.KeyError{}} <- @store.fetch(id), do: :miss)
  end
end
