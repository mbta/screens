defmodule Screens.V2.Departure.Builder do
  @moduledoc false

  alias Screens.Predictions.Prediction
  alias Screens.Stops.Stop
  alias Screens.Trips.Trip
  alias Screens.V2.Departure
  alias Screens.Vehicles.Vehicle

  def get_relevant_departures(predictions_or_schedules, now \\ DateTime.utc_now()) do
    predictions_or_schedules
    |> Stream.reject(&in_past_or_nil_time?(&1, now))
    |> Stream.reject(&multi_route_duplicate?/1)
    |> Stream.reject(&vehicle_already_departed?/1)
    |> choose_earliest_stop_per_trip()
  end

  defp in_past_or_nil_time?(%{arrival_time: nil, departure_time: nil}, _), do: true

  defp in_past_or_nil_time?(%{departure_time: nil, arrival_time: t}, now) do
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

  defp choose_earliest_stop_per_trip(predictions_or_schedules) do
    {departures_without_trip, departures_with_trip} =
      Enum.split_with(predictions_or_schedules, fn
        %{trip: nil} -> true
        %{trip: %{id: nil}} -> true
        _ -> false
      end)

    deduplicated_predictions_with_trip =
      departures_with_trip
      |> Enum.group_by(fn %{trip: %Trip{id: trip_id}} -> trip_id end)
      |> Enum.map(fn {_trip_id, departures} -> Enum.min_by(departures, & &1.departure_time) end)

    departures_without_trip
    |> Kernel.++(deduplicated_predictions_with_trip)
    |> Enum.sort_by(& &1.departure_time)
  end

  def merge_predictions_and_schedules(predictions, schedules) do
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

    predicted_departures =
      predictions
      |> Enum.map(fn
        %{trip: %{id: trip_id}} = p when not is_nil(trip_id) ->
          %Departure{prediction: p, schedule: Map.get(schedules_by_trip_id, trip_id)}

        p ->
          %Departure{prediction: p}
      end)

    unpredicted_departures =
      schedules
      |> Enum.filter(fn
        %{trip: %{id: trip_id}} when not is_nil(trip_id) ->
          trip_id not in predicted_trip_ids

        _ ->
          false
      end)
      |> Enum.map(fn s -> %Departure{schedule: s} end)

    predicted_departures
    |> Kernel.++(unpredicted_departures)
    |> Enum.sort_by(&Departure.time/1)
  end
end
