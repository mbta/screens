defmodule Screens.DeviceMonitor.Store do
  @moduledoc """
  Stores the timestamp of the last device monitor run, allowing it to determine the correct time
  range for logging and avoid multiple app instances logging at the same time.
  """

  use GenServer

  @backend Application.compile_env!(:screens, [__MODULE__, :backend])

  def init(_arg), do: {:ok, nil}

  defdelegate start_link(opts \\ []), to: @backend
  defdelegate get_and_update(server, value), to: @backend

  defmodule Backend do
    @moduledoc "Behaviour for storage backends."

    @doc "Starts the backend."
    @callback start_link(GenServer.options()) :: GenServer.on_start()

    @doc "Updates the stored value and returns the previous value (`nil` if there was none)."
    @callback get_and_update(server :: GenServer.server(), value :: term()) ::
                {:ok, old_value :: term()} | {:error, atom() | binary()}
  end

  defmodule Local do
    @moduledoc """
    Stores the value on the local instance. Not for use in production, since multiple instances
    will not be aware of each others' updates.
    """

    @behaviour Screens.DeviceMonitor.Store.Backend

    @impl true
    def start_link(opts), do: Agent.start_link(fn -> nil end, opts)

    @impl true
    def get_and_update(agent, value),
      do: Agent.get_and_update(agent, fn old_value -> {{:ok, old_value}, value} end)
  end

  defmodule Memcached do
    @moduledoc """
    Stores the value in Memcached. Uses CAS to ensure a consistent view of the value across app
    instances (if the value is A and two instances both attempt to update it at the same time,
    exactly one of them will see the "previous value" as A and the other will see it as whatever
    the first instance set it to).
    """

    @behaviour Screens.DeviceMonitor.Store.Backend
    @key to_string(__MODULE__)

    @impl true
    def start_link(opts), do: Screens.Memcache.start_link(opts)

    @impl true
    def get_and_update(server, value, retries_left \\ 5)

    def get_and_update(_server, _value, 0 = _retries_left), do: {:error, :retry_limit_exceeded}

    def get_and_update(server, value, retries_left) do
      case Memcache.get(server, @key, cas: true) do
        {:ok, old_value, version} ->
          case Memcache.set_cas(server, @key, value, version) do
            {:ok} -> {:ok, old_value}
            # someone else updated it between the `get` and the `set_cas`
            # https://hexdocs.pm/memcachex/0.5.7/Memcache.html#module-cas
            {:error, "Key exists"} -> get_and_update(server, value, retries_left - 1)
            {:error, _} = error -> error
          end

        {:error, "Key not found"} ->
          case Memcache.add(server, @key, value) do
            {:ok, _version} -> {:ok, nil}
            # someone else created it between the `get` and the `add`
            {:error, "Key exists"} -> get_and_update(server, value, retries_left - 1)
            {:error, _} = error -> error
          end

        {:error, _} = error ->
          error
      end
    end
  end
end
