defmodule Screens.V2.Departure.Builder do
  @moduledoc false

  alias Screens.Departures.Departure
  alias Screens.Predictions.Prediction
  alias Screens.Schedules.Schedule
  alias Screens.Stops.Stop
  alias Screens.Trips.Trip
  alias Screens.V2.Departure
  alias Screens.Vehicles.Vehicle

  @typep opts :: [include_scheduled_cancelled?: boolean()]

  @doc """
  Merges Predictions and Schedules into Departures, and filters out any which should not be
  presented to riders.
  """
  @spec build([Prediction.t()], [Schedule.t()], now :: DateTime.t()) :: [Departure.t()]
  @spec build([Prediction.t()], [Schedule.t()], now :: DateTime.t(), opts()) :: [Departure.t()]
  def build(predictions, schedules, now, opts \\ []) do
    predicted_trip_ids =
      predictions
      |> Enum.reject(&is_nil(&1.trip))
      |> Enum.map(& &1.trip.id)
      |> Enum.reject(&is_nil/1)
      |> Enum.into(MapSet.new())

    schedules_by_trip_id =
      schedules
      |> Enum.map(fn %{trip: %{id: trip_id}} = s -> {trip_id, s} end)
      |> Enum.into(%{})

    scheduled_only =
      schedules
      |> Enum.filter(fn
        %{trip: %{id: trip_id}} when not is_nil(trip_id) -> trip_id not in predicted_trip_ids
        _ -> false
      end)

    (predictions ++ scheduled_only)
    |> Enum.map(&map_to_departure(&1, schedules_by_trip_id))
    |> relevant_departures(now, opts)
    |> Enum.sort_by(&Departure.time/1, DateTime)
  end

  defp relevant_departures(departures, now, opts) do
    departures
    |> Stream.reject(&unscheduled_cancelled?(&1))
    |> maybe_reject_scheduled_cancelled(opts)
    |> Stream.reject(&in_past_or_nil_time?(&1, now))
    |> Stream.reject(&multi_route_duplicate?(&1))
    |> Stream.reject(&vehicle_already_departed?(&1))
    |> choose_earliest_arrival_per_trip()
  end

  defp map_to_departure(%Schedule{} = schedule, _schedules_by_trip_id),
    do: %Departure{schedule: schedule}

  defp map_to_departure(%Prediction{trip: %{id: trip_id}} = prediction, schedules_by_trip_id),
    do: %Departure{
      prediction: prediction,
      schedule: Map.get(schedules_by_trip_id, trip_id)
    }

  # There isn't much we can do with a cancelled departure with no schedule information other than
  # not present it at all, so always reject those (unclear whether we'd even produce them)
  defp unscheduled_cancelled?(%Departure{schedule: schedule} = departure),
    do: is_nil(schedule) and Departure.cancelled?(departure)

  # Temporary option enables gradual implementation of displaying skipped/cancelled departures.
  # This step of the pipeline can be deleted once all screen types support this.
  defp maybe_reject_scheduled_cancelled(departures, opts) do
    if Keyword.get(opts, :include_scheduled_cancelled?, false),
      do: departures,
      else: Stream.reject(departures, &Departure.cancelled?/1)
  end

  defp in_past_or_nil_time?(
         %Departure{prediction: %Prediction{departure_time: departure_time}},
         now
       )
       when not is_nil(departure_time) do
    DateTime.compare(departure_time, now) == :lt
  end

  defp in_past_or_nil_time?(
         %Departure{schedule: %Schedule{departure_time: departure_time}},
         now
       )
       when not is_nil(departure_time) do
    DateTime.compare(departure_time, now) == :lt
  end

  defp in_past_or_nil_time?(_, _), do: true

  defp multi_route_duplicate?(%Departure{
         prediction: %Prediction{route: %{id: id1}, trip: %{route_id: id2}}
       }),
       do: id1 != id2

  defp multi_route_duplicate?(%Departure{
         schedule: %Schedule{route: %{id: id1}, trip: %{route_id: id2}}
       }),
       do: id1 != id2

  defp multi_route_duplicate?(_), do: false

  defp vehicle_already_departed?(%Departure{
         prediction: %Prediction{
           stop: %Stop{id: prediction_stop},
           trip: %Trip{id: trip_trip_id, stops: stops},
           vehicle: %Vehicle{
             trip_id: vehicle_trip_id,
             stop_id: vehicle_stop
           }
         }
       })
       when not is_nil(trip_trip_id) and not is_nil(vehicle_trip_id) and not is_nil(vehicle_stop) do
    trip_ids_match? = trip_trip_id == vehicle_trip_id

    prediction_stop_index = Enum.find_index(stops, fn stop -> stop == prediction_stop end)
    vehicle_stop_index = Enum.find_index(stops, fn stop -> stop == vehicle_stop end)

    vehicle_has_passed? =
      not is_nil(prediction_stop_index) and not is_nil(vehicle_stop_index) and
        vehicle_stop_index > prediction_stop_index

    trip_ids_match? and vehicle_has_passed?
  end

  defp vehicle_already_departed?(_), do: false

  defp choose_earliest_arrival_per_trip(departures) do
    departures
    |> Enum.group_by(&Departure.trip_id(&1))
    |> Enum.map(fn {_trip_id, departures} ->
      Enum.min_by(departures, &Departure.time(&1), DateTime)
    end)
  end
end
