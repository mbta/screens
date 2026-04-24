defmodule Screens.LastTrip.LastTrip do
  @moduledoc """
  Last Trip of the Day cache interface
  """
  alias Screens.LastTrip.Cache
  alias Screens.Predictions.Prediction
  alias Screens.V2.Departure
  alias Screens.V2.RDS

  @callback update_last_trip_cache([Departure.t()], DateTime.t()) :: :ok
  def update_last_trip_cache(departures, now) do
    departures
    |> Enum.filter(&Departure.last_trip?(&1))
    |> Enum.group_by(
      &{Departure.stop(&1).id, Departure.route(&1).line.id,
       Departure.representative_headsign(&1)},
      fn %Departure{prediction: %Prediction{departure_time: departure_time}} -> departure_time end
    )
    |> Enum.each(fn {destination_key, new_departure_times} ->
      last_trip_times =
        case Cache.get(destination_key) do
          {:ok, %MapSet{} = departure_times} -> departure_times
          _ -> MapSet.new()
        end

      new_last_trip_times = MapSet.new(new_departure_times)

      unless MapSet.subset?(new_last_trip_times, last_trip_times) do
        combined_last_trip_times = MapSet.union(new_last_trip_times, last_trip_times)

        Cache.put(destination_key, combined_last_trip_times, ttl: time_to_service_end(now))
      end
    end)

    :ok
  end

  @callback last_trip_departure_times(RDS.destination_key()) :: [DateTime.t()]
  def last_trip_departure_times(destination_key) do
    case Cache.get(destination_key) do
      {:ok, nil} -> []
      {:ok, departure_times} -> MapSet.to_list(departure_times)
    end
  end

  defp time_to_service_end(%DateTime{time_zone: time_zone} = now) do
    service_end_time =
      now
      |> DateTime.to_date()
      |> DateTime.new!(~T[04:00:00], time_zone)

    if DateTime.compare(now, service_end_time) == :gt do
      service_end_time
      |> DateTime.add(1, :day)
    else
      service_end_time
    end
    |> DateTime.diff(now, :millisecond)
  end
end
