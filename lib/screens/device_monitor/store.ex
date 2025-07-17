defmodule Screens.DeviceMonitor.Store do
  @moduledoc """
  Stores the timestamp of the last device monitor run, allowing it to determine the correct time
  range for logging and avoid multiple app instances logging at the same time.
  """

  use GenServer

  @backend Application.compile_env!(:screens, [__MODULE__, :backend])

  def init(_arg), do: {:ok, nil}

  defdelegate start_link(opts \\ []), to: @backend
  defdelegate get(server), to: @backend
  defdelegate set(server, value, version), to: @backend

  defmodule Backend do
    @moduledoc "Behaviour for storage backends."

    @typep backend_error :: {:error, atom() | binary()}

    @doc "Starts the backend."
    @callback start_link(GenServer.options()) :: GenServer.on_start()

    @doc """
    Gets the stored value and a version tag to be used with `set/3`. The value is `nil` if no
    value has been previously stored.
    """
    @callback get(server :: GenServer.server()) ::
                {:ok, value :: term(), version :: term()} | backend_error()

    @doc """
    Sets the stored value only if it has not changed since the version previously retrieved with
    a call to `get/1`. Returns `:conflict` when the value has changed.
    """
    @callback set(server :: GenServer.server(), value :: term(), version :: term()) ::
                :ok | :conflict | backend_error()
  end

  defmodule Local do
    @moduledoc """
    Stores the value on the local instance. Not for use in production, since multiple instances
    will not be aware of each others' updates.
    """

    @behaviour Screens.DeviceMonitor.Store.Backend

    @impl true
    def start_link(opts), do: Agent.start_link(fn -> {nil, make_ref()} end, opts)

    @impl true
    def get(agent), do: Agent.get(agent, fn {value, version} -> {:ok, value, version} end)

    @impl true
    def set(agent, value, version) do
      Agent.get_and_update(agent, fn
        {_existing, ^version} -> {:ok, {value, make_ref()}}
        other -> {:conflict, other}
      end)
    end
  end

  defmodule Memcached do
    @moduledoc "Stores the value in Memcached."

    @behaviour Screens.DeviceMonitor.Store.Backend
    @key to_string(__MODULE__)

    @impl true
    def start_link(opts), do: Screens.Memcache.start_link(opts)

    @impl true
    def get(server) do
      case Memcache.get(server, @key, cas: true) do
        {:ok, _, _} = result -> result
        # Memcached version tags are integers, so use `nil` as a special "version" indicating no
        # value has been stored yet, handled by a distinct clause of `set/3`
        {:error, "Key not found"} -> {:ok, nil, nil}
        {:error, _} = error -> error
      end
    end

    @impl true
    def set(server, value, nil) do
      server |> Memcache.add(@key, value) |> handle_store_result()
    end

    def set(server, value, version) do
      server |> Memcache.set_cas(@key, value, version) |> handle_store_result()
    end

    defp handle_store_result({:ok}), do: :ok
    # "Key exists" is the error returned both when attempting to `add` a key that already exists,
    # and when attempting to `set_cas` a key whose value has changed since the given version:
    # https://hexdocs.pm/memcachex/0.5.7/Memcache.html#module-cas
    defp handle_store_result({:error, "Key exists"}), do: :conflict
    defp handle_store_result({:error, _} = error), do: error
  end
end
