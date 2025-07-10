defmodule Screens.DeviceMonitor do
  @moduledoc """
  Periodically fetches and logs screen hardware data from vendor device management systems.
  """

  defmodule State do
    @moduledoc false
    @enforce_keys [:store]
    defstruct @enforce_keys
  end

  defmodule Vendor do
    @moduledoc "Behaviour for vendor-specific logging modules."
    @callback log(report_range :: {DateTime.t(), DateTime.t()}) :: any()
  end

  @vendor_modules [__MODULE__.Gds, __MODULE__.Mercury]

  use GenServer
  require Logger

  alias __MODULE__.Store

  def start_link(opts \\ []) do
    with {:ok, store} <- Store.start_link(),
         do: GenServer.start_link(__MODULE__, %State{store: store}, opts)
  end

  @impl true
  def init(state) do
    send(self(), :log)
    {:ok, state}
  end

  @impl true
  def handle_info(:log, %State{store: store} = state) do
    now = DateTime.utc_now()

    log_fields =
      case Store.get_and_update(store, now) do
        {:ok, nil} ->
          [result: :skip, reason: :store_initialized]

        {:ok, last_update} ->
          {from, to} = {truncate_seconds(last_update), truncate_seconds(now)}

          if DateTime.compare(from, to) == :lt do
            Enum.each(@vendor_modules, fn module ->
              Task.start(fn -> module.log({from, to}) end)
            end)

            [result: :ok]
          else
            [result: :skip, reason: :invalid_time_range, from: from, to: to]
          end

        {:error, error} ->
          [result: :error, error: error]
      end

    Logger.info(
      "device_monitor " <>
        Enum.map_join(log_fields, " ", fn {key, value} -> "#{key}=#{inspect(value)}" end)
    )

    schedule_next_run()

    {:noreply, state}
  end

  # Handle leaked :ssl_closed messages from Hackney.
  # Workaround for this issue: https://github.com/benoitc/hackney/issues/464
  def handle_info({:ssl_closed, _}, state) do
    {:noreply, state}
  end

  defp schedule_next_run do
    # Run at the top of the next minute, plus a second to ensure we've cleared the boundary
    now = DateTime.utc_now()
    next = now |> truncate_seconds() |> DateTime.add(1, :minute) |> DateTime.add(1, :second)
    Process.send_after(self(), :log, DateTime.diff(next, now, :millisecond))
  end

  defp truncate_seconds(dt),
    do: dt |> DateTime.truncate(:second) |> then(&%DateTime{&1 | second: 0})
end
