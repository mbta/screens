defmodule Screens.LastTrip do
  @moduledoc """
  Supervisor and public interface for fetching information about the last trips
  of the day (AKA Last Train of the Day, LTOTD).
  """
  alias Screens.LastTrip.Cache
  alias Screens.LastTrip.Poller
  use Supervisor

  @spec start_link(any()) :: Supervisor.on_start()
  def start_link(_) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_) do
    children = [
      Cache.LastTrips,
      Cache.RecentDepartures,
      Poller
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  @spec last_trip?(trip_id :: String.t()) :: boolean()
  defdelegate last_trip?(trip_id), to: Cache

  @spec service_ended_for_rds?(Cache.rds()) :: boolean()
  def service_ended_for_rds?({_r, _d, _s} = rds, now_fn \\ &DateTime.utc_now/0) do
    now_unix = now_fn.() |> DateTime.to_unix()

    rds
    |> Cache.get_recent_departures()
    |> Enum.any?(fn {trip_id, departure_time_unix} ->
      seconds_since_departure = now_unix - departure_time_unix

      seconds_since_departure > 3 and last_trip?(trip_id)
    end)
  end
end
