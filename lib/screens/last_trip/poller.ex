defmodule Screens.LastTrip.Poller do
  @moduledoc """
  GenServer that polls predictions to calculate the last trip of the day
  """
  require Logger
  alias Screens.LastTrip.Cache
  alias Screens.LastTrip.Parser
  alias Screens.LastTrip.TripUpdates
  alias Screens.LastTrip.VehiclePositions
  use GenServer

  defstruct [:next_reset]

  @polling_interval :timer.seconds(1)

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_) do
    state = %__MODULE__{next_reset: next_reset()}

    send(self(), :poll)

    {:ok, state}
  end

  @impl true
  def handle_info(:poll, %__MODULE__{} = state) do
    state =
      if DateTime.after?(now(), state.next_reset) do
        :ok = Cache.reset()
        %{state | next_reset: next_reset()}
      else
        case fetch_trip_updates_and_vehicle_positions() do
          {:ok,
           %{
             trip_updates: trip_updates,
             vehicle_positions: vehicle_positions
           }} ->
            update_last_trips(trip_updates)
            update_recent_departures(trip_updates, vehicle_positions)

          {:error, error} ->
            Logger.warning(
              "[last_trip_poller] failed while polling for new data: #{inspect(error)}"
            )
        end

        state
      end

    Process.send_after(self(), :poll, @polling_interval)

    {:noreply, state}
  end

  defp fetch_trip_updates_and_vehicle_positions do
    with {:ok, %{status_code: 200, body: trip_updates}} <- TripUpdates.get(),
         {:ok, %{status_code: 200, body: vehicle_positions}} <- VehiclePositions.get() do
      {:ok,
       %{
         trip_updates: trip_updates,
         vehicle_positions: vehicle_positions
       }}
    end
  end

  defp update_last_trips(trip_updates) do
    trip_updates
    |> Parser.get_last_trips()
    |> Enum.map(&{&1, true})
    |> Cache.update_last_trips()
  end

  defp update_recent_departures(trip_updates, vehicle_positions) do
    trip_updates
    |> Parser.get_recent_departures(vehicle_positions)
    |> Cache.update_recent_departures()
  end

  defp now(now_fn \\ &DateTime.utc_now/0) do
    now_fn.() |> DateTime.shift_zone!("America/New_York")
  end

  defp next_reset do
    now()
    |> DateTime.add(1, :day)
    |> DateTime.to_date()
    |> DateTime.new!(~T[03:30:00], "America/New_York")
  end
end
