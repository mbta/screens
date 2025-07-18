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
  def handle_info(:run, state) do
    log_data(state)
    schedule_next_run(state)
    {:noreply, state}
  end

  # vendor module task result
  def handle_info({_ref, :ok}, state), do: {:noreply, state}

  # vendor module process completed or crashed
  def handle_info({:DOWN, _ref, :process, _pid, _reason}, state), do: {:noreply, state}

  defp log_data(%State{now_fn: now_fn, store: store, vendor_mods: vendor_mods}) do
    now = now_fn.()

    log_fields =
      with {:ok, prev, version} <- get_or_initialize(store, now),
           [from, to] = Enum.map([prev, now], &truncate_seconds/1),
           {:diff, true} <- {:diff, DateTime.diff(to, from, :minute) >= 1},
           :ok <- Store.set(store, now, version) do
        Enum.each(vendor_mods, fn vendor_mod ->
          Task.Supervisor.async_nolink(__MODULE__.Supervisor, fn -> vendor_mod.log({from, to}) end)
        end)

        [result: :started, from: from, to: to]
      else
        :initialized -> [result: :skipped, reason: :store_initialized]
        :conflict -> [result: :skipped, reason: :store_conflict]
        {:diff, false} -> [result: :skipped, reason: :interval_not_elapsed]
        {:error, error} -> [result: :error, reason: error]
      end

    Logger.info(
      "device_monitor " <>
        Enum.map_join(log_fields, " ", fn {key, value} -> "#{key}=\"#{value}\"" end)
    )
  end

  defp get_or_initialize(store, value) do
    with {:ok, nil, version} <- Store.get(store),
         :ok <- Store.set(store, value, version),
         do: :initialized
  end

  defp schedule_next_run(%State{now_fn: now_fn}) do
    now = now_fn.()

    # run at a consistent time past the top of the minute
    send_after =
      now
      |> truncate_seconds()
      |> DateTime.add(1, :minute)
      |> DateTime.add(1, :second)
      |> DateTime.diff(now, :millisecond)

    Process.send_after(self(), :run, send_after)
  end

  defp truncate_seconds(dt), do: DateTime.truncate(%DateTime{dt | second: 0}, :second)
end
