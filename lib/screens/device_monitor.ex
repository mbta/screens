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

  @log_interval_minutes 5
  # ensure logging functions don't run for longer than the log interval
  @vendor_mod_timeout_ms 4 * 60 * 1000

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
      case Store.get_and_update(store, now) do
        {:ok, nil} ->
          [result: :skipped, reason: :store_initialized]

        {:ok, last_update} ->
          {from, to} = {truncate_seconds(last_update), truncate_seconds(now)}

          case DateTime.compare(from, to) do
            :lt ->
              Enum.each(vendor_mods, fn vendor_mod ->
                Task.Supervisor.async_nolink(
                  __MODULE__.Supervisor,
                  fn -> vendor_mod.log({from, to}) end,
                  timeout: @vendor_mod_timeout_ms
                )
              end)

              [result: :started, from: from, to: to]

            :eq ->
              # expected and will usually mean another instance won the race
              [result: :skipped, reason: :empty_time_range, from: from, to: to]

            :gt ->
              [result: :error, reason: :invalid_time_range, from: from, to: to]
          end

        {:error, error} ->
          [result: :error, reason: error]
      end

    Logger.info(
      "device_monitor " <>
        Enum.map_join(log_fields, " ", fn {key, value} -> "#{key}=\"#{value}\"" end)
    )
  end

  defp schedule_next_run(%State{now_fn: now_fn}) do
    now = now_fn.()

    # run at a consistent time past the top of the minute
    send_after =
      now
      |> truncate_seconds()
      |> DateTime.add(@log_interval_minutes, :minute)
      |> DateTime.add(1, :second)
      |> DateTime.diff(now, :millisecond)

    Process.send_after(self(), :run, send_after)
  end

  defp truncate_seconds(dt),
    do: dt |> DateTime.truncate(:second) |> then(&%DateTime{&1 | second: 0})
end
