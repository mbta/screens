defmodule Screens.DeviceMonitor do
  @moduledoc """
  Periodically fetches and logs screen hardware data from vendor device management systems.
  """

  defmodule State do
    @moduledoc false

    @vendor_mods [Screens.DeviceMonitor.Gds, Screens.DeviceMonitor.Mercury]

    @enforce_keys [:store]
    defstruct @enforce_keys ++ [now_fn: &DateTime.utc_now/0, vendor_mods: @vendor_mods]
  end

  defmodule Vendor do
    @moduledoc "Behaviour for vendor-specific logging modules."
    @callback log(report_range :: {DateTime.t(), DateTime.t()}) :: any()
  end

  use GenServer
  require Logger

  alias __MODULE__.Store

  def start_link(opts \\ []) do
    with {:ok, store} <- Store.start_link(),
         do: GenServer.start_link(__MODULE__, %State{store: store}, opts)
  end

  @impl true
  def init(state) do
    send(self(), :run)
    {:ok, state}
  end

  @impl true
  def handle_info(:run, %State{now_fn: now_fn, store: store, vendor_mods: vendor_mods} = state) do
    now = now_fn.()

    log_fields =
      case Store.get_and_update(store, now) do
        {:ok, nil} ->
          [result: :skip, reason: :store_initialized]

        {:ok, last_update} ->
          {from, to} = {truncate_seconds(last_update), truncate_seconds(now)}

          case DateTime.compare(from, to) do
            :lt ->
              Enum.each(vendor_mods, fn module ->
                Task.start(fn -> module.log({from, to}) end)
              end)

              [result: :ok]

            :eq ->
              # expected and will usually mean another instance won the race
              [result: :skip, reason: :empty_time_range]

            :gt ->
              [result: :error, reason: :invalid_time_range, from: from, to: to]
          end

        {:error, error} ->
          [result: :error, reason: error]
      end

    Logger.info(
      "device_monitor " <>
        Enum.map_join(log_fields, " ", fn {key, value} -> "#{key}=#{inspect(value)}" end)
    )

    schedule_next_run(now)

    {:noreply, state}
  end

  defp schedule_next_run(now) do
    # run at the top of the next minute, plus a second to ensure we've cleared the boundary
    next = now |> truncate_seconds() |> DateTime.add(1, :minute) |> DateTime.add(1, :second)
    Process.send_after(self(), :run, DateTime.diff(next, now, :millisecond))
  end

  defp truncate_seconds(dt),
    do: dt |> DateTime.truncate(:second) |> then(&%DateTime{&1 | second: 0})
end
