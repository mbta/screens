defmodule Screens.V2.Departure do
  @moduledoc false

  alias Screens.Predictions.Prediction
  alias Screens.Routes.Route
  alias Screens.Schedules.Schedule
  alias Screens.Trips.Trip
  alias Screens.V2.Departure.Builder
  alias Screens.Vehicles.Vehicle

  @type t :: %__MODULE__{
          prediction: Screens.Predictions.Prediction.t() | nil,
          schedule: Screens.Schedules.Schedule.t() | nil
        }

  defstruct prediction: nil,
            schedule: nil

  def fetch(params, opts \\ []) do
    # This is equivalent to an argument with a default value, so it's fine
    # credo:disable-for-next-line Screens.Checks.UntestableDateTime
    now = Keyword.get(opts, :now, DateTime.utc_now())

    if opts[:include_schedules] do
      fetch_predictions_and_schedules(params, now)
    else
      fetch_predictions_only(params, now)
    end
  end

  def fetch_predictions_and_schedules(params, now) do
    with {:ok, predictions} <- Prediction.fetch(params),
         {:ok, schedules} <- Schedule.fetch(params) do
      relevant_predictions = Builder.get_relevant_departures(predictions, now)
      relevant_schedules = Builder.get_relevant_departures(schedules, now)

      departures =
        Builder.merge_predictions_and_schedules(relevant_predictions, relevant_schedules)

      {:ok, departures}
    else
      _ -> :error
    end
  end

  def fetch_predictions_only(params, now) do
    case Prediction.fetch(params) do
      {:ok, predictions} ->
        relevant_predictions = Builder.get_relevant_departures(predictions, now)
        departures = Enum.map(relevant_predictions, fn p -> %__MODULE__{prediction: p} end)
        {:ok, departures}

      :error ->
        :error
    end
  end

  ### Accessor functions
  def alerts(%__MODULE__{prediction: p}) when not is_nil(p) do
    %Prediction{alerts: alerts} = p
    alerts
  end

  def alerts(%__MODULE__{prediction: nil, schedule: _}), do: []

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

  def direction_id(%__MODULE__{prediction: %Prediction{trip: %Trip{direction_id: direction_id}}}) do
    direction_id
  end

  def direction_id(%__MODULE__{prediction: nil, schedule: s}) do
    case s do
      %Schedule{trip: %Trip{direction_id: direction_id}} -> direction_id
      _ -> nil
    end
  end

  def headsign(%__MODULE__{prediction: p, schedule: s}) when not is_nil(p) do
    %Prediction{trip: %Trip{headsign: headsign}} = p

    case s do
      %Schedule{stop_headsign: stop_headsign} when not is_nil(stop_headsign) ->
        stop_headsign

      _ ->
        headsign
    end
  end

  def headsign(%__MODULE__{prediction: nil, schedule: s}) do
    case s do
      %Schedule{stop_headsign: stop_headsign} when not is_nil(stop_headsign) ->
        stop_headsign

      %Schedule{trip: %Trip{headsign: headsign}} ->
        headsign
    end
  end

  def id(%__MODULE__{prediction: %Prediction{id: prediction_id}}), do: prediction_id
  def id(%__MODULE__{schedule: %Schedule{id: schedule_id}}), do: schedule_id

  def route_id(%__MODULE__{prediction: %Prediction{route: %Route{id: route_id}}}) do
    route_id
  end

  def route_id(%__MODULE__{prediction: nil, schedule: %Schedule{route: %Route{id: route_id}}}) do
    route_id
  end

  def route_name(%__MODULE__{
        prediction: %Prediction{
          route: %Route{short_name: short_name, long_name: long_name, type: type}
        }
      }) do
    do_route_name(type, short_name, long_name)
  end

  def route_name(%__MODULE__{
        prediction: nil,
        schedule: %Schedule{
          route: %Route{short_name: short_name, long_name: long_name, type: type}
        }
      }) do
    do_route_name(type, short_name, long_name)
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

  def scheduled_time(%__MODULE__{schedule: s}) when not is_nil(s) do
    select_departure_time(s)
  end

  def scheduled_time(_), do: nil

  def stop_type(%__MODULE__{
        prediction: %Prediction{arrival_time: arrival_time, departure_time: departure_time}
      }) do
    identify_stop_type_from_times(arrival_time, departure_time)
  end

  def stop_type(%__MODULE__{
        prediction: nil,
        schedule: %Schedule{arrival_time: arrival_time, departure_time: departure_time}
      }) do
    identify_stop_type_from_times(arrival_time, departure_time)
  end

  def time(%__MODULE__{prediction: p}) when not is_nil(p) do
    select_departure_time(p)
  end

  def time(%__MODULE__{prediction: nil, schedule: s}) do
    select_departure_time(s)
  end

  def track_number(%__MODULE__{prediction: %Prediction{track_number: track_number}})
      when not is_nil(track_number) do
    track_number
  end

  def track_number(%__MODULE__{schedule: %Schedule{track_number: track_number}})
      when not is_nil(track_number) do
    track_number
  end

  def track_number(_), do: nil

  def vehicle_status(%__MODULE__{
        prediction: %Prediction{vehicle: %Vehicle{current_status: current_status}}
      }) do
    current_status
  end

  def vehicle_status(_), do: nil

  defp do_route_name(type, short_name, long_name) do
    case type do
      :bus -> short_name
      _ -> long_name
    end
  end

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

  defp select_departure_time(%{arrival_time: t, departure_time: nil}), do: t
  defp select_departure_time(%{arrival_time: _, departure_time: t}), do: t

  defp identify_stop_type_from_times(arrival_time, departure_time)
  defp identify_stop_type_from_times(nil, _), do: :first_stop
  defp identify_stop_type_from_times(_, nil), do: :last_stop
  defp identify_stop_type_from_times(_, _), do: :mid_route_stop
end
