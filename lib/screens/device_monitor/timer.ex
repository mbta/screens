defmodule Screens.DeviceMonitor.Timer do
  use GenServer

  @storage Application.compile_env!(:screens, [__MODULE__, :storage])

  def init(_arg), do: {:ok, nil}

  @spec start_link(GenServer.options()) :: GenServer.on_start()
  defdelegate start_link(opts), to: @storage

  @spec next(binary(), now :: DateTime.t()) :: {
          {:ok, range :: {DateTime.t(), DateTime.t()}} | :ignore | {:error, atom() | binary()},
          next :: DateTime.t()
        }
  def next(key, now) do
    result =
      case @storage.get_and_update(key, now) do
        {:ok, last_update} ->
          case {set_second(last_update, 0), set_second(now, 0)} do
            {dt, dt} -> :ignore
            range -> {:ok, range}
          end

        :conflict ->
          :ignore

        :created ->
          :ignore

        {:error, _} = error ->
          error
      end

    {result, now |> set_second(5) |> DateTime.add(1, :minute)}
  end

  defp set_second(%DateTime{} = dt, second),
    do: dt |> DateTime.truncate(:second) |> then(&%DateTime{&1 | second: second})

  defmodule Storage do
    @callback start_link(GenServer.options()) :: GenServer.on_start()
    @callback get_and_update(key :: binary(), value :: term()) ::
                {:ok, old_value :: term()} | :conflict | :created | {:error, term()}
  end

  defmodule Local do
    @behaviour Screens.DeviceMonitor.Timer.Storage

    def start_link(_opts), do: Agent.start_link(&Map.new/0, name: __MODULE__)

    def get_and_update(key, value) do
      Agent.get_and_update(__MODULE__, fn state ->
        Map.get_and_update(state, key, fn
          nil -> {:created, value}
          old_value -> {{:ok, old_value}, value}
        end)
      end)
    end
  end

  defmodule Memcached do
    @behaviour Screens.DeviceMonitor.Timer.Storage

    def start_link(_opts), do: Screens.Memcache.start_link(name: __MODULE__)

    def get_and_update(key, value) do
      case Memcache.get(__MODULE__, key, cas: true) do
        {:ok, old_value, version} ->
          case Memcache.set_cas(__MODULE__, key, value, version) do
            {:ok} -> {:ok, old_value}
            # someone else updated it between the `get` and the `set_cas`
            # https://hexdocs.pm/memcachex/0.5.7/Memcache.html#module-cas
            {:error, "Key exists"} -> :conflict
            {:error, _} = error -> error
          end

        {:error, "Key not found"} ->
          case Memcache.add(__MODULE__, key, value) do
            {:ok, _version} -> :created
            # someone else created it between the `get` and the `add`
            {:error, "Key exists"} -> :conflict
            {:error, _} = error -> error
          end

        {:error, _} = error ->
          error
      end
    end
  end
end
