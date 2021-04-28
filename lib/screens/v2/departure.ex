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
        departures = Enum.map(predictions, fn p -> %__MODULE__{prediction: p} end)
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
      %Prediction{vehicle: %Vehicle{occupancy_status: occupancy_status}} ->
        crowding_level_from_occupancy_status(occupancy_status)

      _ ->
        nil
    end
  end

  def crowding_level(%__MODULE__{prediction: nil, schedule: _}), do: nil

  defp crowding_level_from_occupancy_status(:many_seats_available), do: 1
  defp crowding_level_from_occupancy_status(:few_seats_available), do: 2
  defp crowding_level_from_occupancy_status(:full), do: 3
  defp crowding_level_from_occupancy_status(nil), do: nil
end
