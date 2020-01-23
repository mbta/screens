defmodule Screens.Departures.Departure do
  @moduledoc false

  defstruct stop_name: nil,
            route: nil,
            destination: nil,
            time: nil,
            realtime: nil

  @type t :: %__MODULE__{
          stop_name: String.t(),
          route: String.t(),
          destination: String.t(),
          time: DateTime.t(),
          realtime: boolean()
        }

  def by_stop_id(stop_id) do
    predictions = Screens.Predictions.Prediction.by_stop_id(stop_id)
    schedules = Screens.Schedules.Schedule.by_stop_id(stop_id)

    merge_predictions_with_schedules(predictions, schedules)
  end

  def to_map(d) do
    %{
      route: d.route,
      destination: d.destination,
      time: d.time,
      realtime: d.realtime
    }
  end

  def from_prediction(p) do
    %Screens.Departures.Departure{
      stop_name: p.stop.name,
      route: p.route.short_name,
      destination: p.trip.headsign,
      time: DateTime.to_iso8601(p.time),
      realtime: true
    }
  end

  def from_schedule(s) do
    %Screens.Departures.Departure{
      stop_name: nil,
      route: s.route.short_name,
      destination: s.trip.headsign,
      time: DateTime.to_iso8601(s.time),
      realtime: false
    }
  end

  defp merge_predictions_with_schedules(predictions, schedules) do
    # Filter schedules by time
    # We currently filter schedules after the last prediction time, but may want to change that.
    now = DateTime.utc_now()
    last_prediction_time = List.last(predictions).time

    upcoming_schedules =
      Enum.filter(schedules, fn s -> s.time > now && s.time < last_prediction_time end)

    # Combine predictions with schedules based on trip_id
    prediction_trip_ids =
      predictions
      |> Enum.map(& &1.trip.id)
      |> MapSet.new()

    added_schedules =
      Enum.filter(upcoming_schedules, fn s -> !MapSet.member?(prediction_trip_ids, s.trip.id) end)

    predicted_departures = Enum.map(predictions, fn p -> from_prediction(p) end)
    scheduled_departures = Enum.map(added_schedules, fn s -> from_schedule(s) end)
    Enum.sort_by(predicted_departures ++ scheduled_departures, & &1.time)
  end
end
