defmodule Screens.V2.Departure.Builder do
  @moduledoc false

  alias Screens.Departures.Departure
  alias Screens.Predictions.Prediction
  alias Screens.Schedules.Schedule
  alias Screens.Stops.Stop
  alias Screens.Trips.Trip
  alias Screens.V2.Departure
  alias Screens.Vehicles.Vehicle

  @doc """
  Merges Predictions and Schedules into Departures, and filters out any which should not be
  presented to riders.
  """
  @spec build([Prediction.t()], [Schedule.t()], now :: DateTime.t()) :: [Departure.t()]
  def build(predictions, schedules, now) do
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
    |> Enum.map(&map_to_departures(&1, schedules_by_trip_id))
    |> relevant_departures(now)
    |> Enum.sort_by(&Departure.time/1, DateTime)
  end

  defp relevant_departures(departures, now) do
    departures
    |> Stream.reject(&cancelled_or_skipped?(prediction_or_schedule(&1)))
    |> Stream.reject(&in_past_or_nil_time?(prediction_or_schedule(&1), now))
    |> Stream.reject(&multi_route_duplicate?(prediction_or_schedule(&1)))
    |> Stream.reject(&vehicle_already_departed?(prediction_or_schedule(&1)))
    |> choose_earliest_arrival_per_trip()
  end

  defp prediction_or_schedule(%Departure{prediction: %Prediction{} = prediction}), do: prediction
  defp prediction_or_schedule(%Departure{schedule: %Schedule{} = schedule}), do: schedule

  defp map_to_departures(%Schedule{} = schedule, _schedules_by_trip_id),
    do: %Departure{schedule: schedule}

  defp map_to_departures(%Prediction{trip: %{id: trip_id}} = prediction, schedules_by_trip_id)
       when not is_nil(trip_id),
       do: %Departure{
         prediction: prediction,
         schedule: Map.get(schedules_by_trip_id, trip_id)
       }

  defp map_to_departures(%Prediction{} = prediction, _schedules_by_trip_id),
    do: %Departure{prediction: prediction}

  defp cancelled_or_skipped?(%Prediction{schedule_relationship: sr}),
    do: sr in [:cancelled, :skipped]

  defp cancelled_or_skipped?(_), do: false

  defp in_past_or_nil_time?(%{arrival_time: nil, departure_time: nil}, _), do: true

  defp in_past_or_nil_time?(%{arrival_time: t, departure_time: nil}, now) do
    DateTime.compare(t, now) == :lt
  end

  defp in_past_or_nil_time?(%{departure_time: t}, now) do
    DateTime.compare(t, now) == :lt
  end

  defp multi_route_duplicate?(%{route: %{id: id1}, trip: %{route_id: id2}}), do: id1 != id2

  defp multi_route_duplicate?(_), do: false

  defp vehicle_already_departed?(%Prediction{
         stop: %Stop{id: prediction_stop},
         trip: %Trip{id: trip_trip_id, stops: stops},
         vehicle: %Vehicle{
           trip_id: vehicle_trip_id,
           stop_id: vehicle_stop
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
    {departures_without_trip, departures_with_trip} =
      Enum.split_with(departures, fn departure ->
        case Departure.trip_id(departure) do
          nil -> true
          _ -> false
        end
      end)

    deduplicated_predictions_with_trip =
      departures_with_trip
      |> Enum.group_by(&Departure.trip_id(&1))
      |> Enum.map(fn {_trip_id, departures} ->
        Enum.min_by(departures, &earliest_time(prediction_or_schedule(&1)), DateTime)
      end)

    departures_without_trip
    |> Kernel.++(deduplicated_predictions_with_trip)
    |> Enum.sort_by(&earliest_time(prediction_or_schedule(&1)), DateTime)
  end

  # align with `Departure.time/1`
  defp earliest_time(%{arrival_time: time}) when not is_nil(time), do: time
  defp earliest_time(%{departure_time: time}) when not is_nil(time), do: time
  defp earliest_time(_prediction_or_schedule), do: nil
end
