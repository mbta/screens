defmodule Screens.V2.Departure do
  @moduledoc false

  alias Screens.Predictions.Prediction
  alias Screens.Routes.Route
  alias Screens.Schedules.Schedule
  alias Screens.Trips.Trip
  alias Screens.Vehicles.Vehicle

  @type t :: %__MODULE__{
          prediction: Screens.Predictions.Prediction.t() | nil,
          schedule: Screens.Schedules.Schedule.t() | nil
        }

  defstruct prediction: nil,
            schedule: nil

  def fetch(params, opts \\ []) do
    if opts[:include_schedules] do
      fetch_predictions_and_schedules(params)
    else
      fetch_predictions_only(params)
    end
  end

  defp fetch_predictions_and_schedules(params) do
    with {:ok, predictions} <- Prediction.fetch(params),
         {:ok, schedules} <- Schedule.fetch(params) do
      relevant_predictions = get_relevant_departures(predictions)
      relevant_schedules = get_relevant_departures(schedules)
      departures = merge_predictions_and_schedules(relevant_predictions, relevant_schedules)
      {:ok, departures}
    else
      _ -> :error
    end
  end

  defp get_relevant_departures(predictions_or_schedules) do
    predictions_or_schedules
    |> Enum.reject(&in_past_or_nil_time?/1)
    |> Enum.reject(&multi_route_duplicate?/1)
    |> choose_earliest_stop_per_trip()
  end

  defp in_past_or_nil_time?(%{arrival_time: nil, departure_time: nil}), do: true

  defp in_past_or_nil_time?(%{departure_time: nil, arrival_time: t}) do
    DateTime.compare(t, DateTime.utc_now()) == :lt
  end

  defp in_past_or_nil_time?(%{departure_time: t}) do
    DateTime.compare(t, DateTime.utc_now()) == :lt
  end

  defp multi_route_duplicate?(%{route: %{id: id1}, trip: %{route_id: id2}}), do: id1 != id2
  defp multi_route_duplicate?(_), do: false

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

    deduplicated_predictions =
      (departures_without_trip ++ deduplicated_predictions_with_trip)
      |> Enum.sort_by(& &1.departure_time)

    deduplicated_predictions
  end

  defp merge_predictions_and_schedules(predictions, schedules) do
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
          %__MODULE__{prediction: p, schedule: Map.get(schedules_by_trip_id, trip_id)}

        p ->
          %__MODULE__{prediction: p}
      end)

    unpredicted_departures =
      schedules
      |> Enum.filter(fn
        %{trip: %{id: trip_id}} when not is_nil(trip_id) ->
          trip_id not in predicted_trip_ids

        _ ->
          false
      end)
      |> Enum.map(fn s -> %__MODULE__{schedule: s} end)

    predicted_departures ++ unpredicted_departures
  end

  defp fetch_predictions_only(params) do
    case Prediction.fetch(params) do
      {:ok, predictions} ->
        relevant_predictions = get_relevant_departures(predictions)
        departures = Enum.map(relevant_predictions, fn p -> %__MODULE__{prediction: p} end)
        {:ok, departures}

      :error ->
        :error
    end
  end

  ### Accessor functions
  def route_id(%__MODULE__{prediction: p}) when not is_nil(p) do
    %Prediction{route: %Route{id: route_id}} = p
    route_id
  end

  def route_id(%__MODULE__{prediction: nil, schedule: s}) do
    %Schedule{route: %Route{id: route_id}} = s
    route_id
  end

  def headsign(%__MODULE__{prediction: p, schedule: s}) when not is_nil(p) do
    %Prediction{trip: %Trip{headsign: headsign}} = p

    case s do
      nil -> headsign
      %{stop_headsign: nil} -> headsign
      %{stop_headsign: stop_headsign} -> stop_headsign
    end
  end

  def headsign(%__MODULE__{prediction: nil, schedule: s}) do
    %Schedule{trip: %Trip{headsign: headsign}} = s
    headsign
  end

  def alerts(%__MODULE__{prediction: p}) when not is_nil(p) do
    %Prediction{alerts: alerts} = p
    alerts
  end

  def alerts(%__MODULE__{prediction: nil, schedule: _}), do: []

  def time(%__MODULE__{prediction: p}) when not is_nil(p) do
    select_departure_time(p)
  end

  def time(%__MODULE__{prediction: nil, schedule: s}) do
    select_departure_time(s)
  end

  defp select_departure_time(%{arrival_time: t, departure_time: nil}), do: t
  defp select_departure_time(%{arrival_time: _, departure_time: t}), do: t

  def crowding_level(%__MODULE__{prediction: p}) when not is_nil(p) do
    case p do
      %Prediction{trip: %Trip{} = trip, vehicle: %Vehicle{occupancy_status: status} = vehicle} ->
        if crowding_data_relevant?(trip, vehicle) do
          crowding_level_from_occupancy_status(status)
        else
          nil
        end

      _ ->
        nil
    end
  end

  def crowding_level(%__MODULE__{prediction: nil, schedule: _}), do: nil

  defp crowding_data_relevant?(%Trip{id: trip_trip_id, stops: [first_stop | _]}, %Vehicle{
         current_status: current_status,
         trip_id: vehicle_trip_id,
         stop_id: next_stop
       })
       when not is_nil(trip_trip_id) and not is_nil(vehicle_trip_id) do
    vehicle_on_prediction_trip? = trip_trip_id == vehicle_trip_id
    vehicle_started_trip? = not (current_status == :in_transit_to and next_stop == first_stop)
    vehicle_on_prediction_trip? and vehicle_started_trip?
  end

  defp crowding_data_relevant?(_trip, _vehicle), do: false

  defp crowding_level_from_occupancy_status(:many_seats_available), do: 1
  defp crowding_level_from_occupancy_status(:few_seats_available), do: 2
  defp crowding_level_from_occupancy_status(:full), do: 3
  defp crowding_level_from_occupancy_status(nil), do: nil

  def vehicle_status(%__MODULE__{prediction: p}) when not is_nil(p) do
    case p do
      %Prediction{vehicle: %Vehicle{current_status: current_status}} ->
        current_status

      _ ->
        nil
    end
  end

  def vehicle_status(%__MODULE__{prediction: nil, schedule: _}), do: nil

  def stop_type(%__MODULE__{
        prediction: %Prediction{arrival_time: arrival_time, departure_time: departure_time}
      }) do
    case {arrival_time, departure_time} do
      {nil, _} -> :first_stop
      {_, nil} -> :last_stop
      {_, _} -> :mid_route_stop
    end
  end

  def stop_type(%__MODULE__{
        prediction: nil,
        schedule: %Schedule{arrival_time: arrival_time, departure_time: departure_time}
      }) do
    case {arrival_time, departure_time} do
      {nil, _} -> :first_stop
      {_, nil} -> :last_stop
      {_, _} -> :mid_route_stop
    end
  end

  def route_type(%__MODULE__{prediction: %Prediction{route: %Route{type: route_type}}}) do
    route_type
  end

  def route_type(%__MODULE__{
        prediction: nil,
        schedule: %Schedule{route: %Route{type: route_type}}
      }) do
    route_type
  end
end
