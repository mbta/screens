defmodule Screens.MercuryData.State do
  @moduledoc false

  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def schedule_refresh(pid, ms) do
    Process.send_after(pid, :refresh, ms)
    :ok
  end

  ###
  @impl true
  def init(:ok) do
    schedule_refresh(self(), next_minute_ms())
    {:ok, nil}
  end

  @impl true
  def handle_info(:refresh, state) do
    Screens.MercuryData.Logger.log_data()

    schedule_refresh(self(), next_minute_ms())
    {:noreply, state}
  end

  # milliseconds to wait until the start of the next minute
  defp next_minute_ms do
    now = DateTime.utc_now()
    {microsecond, _} = now.microsecond
    current_ms = now.second * 1000 + div(microsecond, 1000)
    60 * 1000 - current_ms
  end
end
