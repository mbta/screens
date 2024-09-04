defmodule Screens.LastTrip.Cache do
  @moduledoc """
  Public interface into the caches that back last trip (LTOTD) tracking
  """
  alias Screens.LastTrip.Cache.LastTrips
  alias Screens.LastTrip.Cache.RecentDepartures

  @type rds :: {route_id :: String.t(), direction_id :: 0 | 1, stop_id :: String.t()}
  @type departing_trip :: {trip_id :: String.t(), departure_time_unix :: integer()}

  @last_trips_ttl :timer.hours(1)
  @recent_departures_ttl :timer.hours(1)

  @spec update_last_trips(
          last_trip_entries :: [{trip_id :: LastTrips.key(), last_trip? :: LastTrips.value()}]
        ) ::
          :ok
  def update_last_trips(last_trips) do
    LastTrips.put_all(last_trips, ttl: @last_trips_ttl)

    :ok
  end

  @spec update_recent_departures(recent_departures :: %{rds() => [departing_trip()]}) :: :ok
  def update_recent_departures(recent_departures, now_fn \\ &DateTime.utc_now/0) do
    expiration = now_fn.() |> DateTime.add(-1, :hour) |> DateTime.to_unix()

    for {rds, departures} <- recent_departures do
      RecentDepartures.update(
        rds,
        departures,
        &merge_and_expire_departures(&1, departures, expiration),
        ttl: @recent_departures_ttl
      )
    end

    :ok
  end

  def merge_and_expire_departures(existing_departures, departures, expiration) do
    existing_departures =
      existing_departures
      |> only_latest_departures()
      |> Map.new()

    departures =
      departures
      |> only_latest_departures()
      |> Map.new()

    existing_departures
    |> Map.merge(departures)
    |> Enum.reject(fn {_, departure_time} -> departure_time <= expiration end)
  end

  @spec last_trip?(trip_id :: String.t()) :: boolean()
  def last_trip?(trip_id) do
    LastTrips.get(trip_id) == true
  end

  @spec get_recent_departures(rds()) :: [departing_trip()]
  def get_recent_departures({_r, _d, _s} = rds) do
    rds
    |> RecentDepartures.get()
    |> List.wrap()
  end

  @spec reset() :: :ok
  def reset do
    LastTrips.delete_all()
    RecentDepartures.delete_all()

    :ok
  end

  defp only_latest_departures(departures) do
    # Only take the latest departure time for each trip
    departures
    |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
    |> Enum.map(fn {trip_id, departure_times} ->
      {trip_id, Enum.max(departure_times)}
    end)
  end
end
