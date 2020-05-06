defmodule Screens.Departures.Departure do
  @moduledoc false

  alias Screens.Predictions.Prediction
  alias Screens.Schedules.Schedule

  defstruct id: nil,
            stop_name: nil,
            route_short_name: nil,
            route_id: nil,
            destination: nil,
            direction_id: nil,
            time: nil,
            inline_badges: nil

  @type t :: %__MODULE__{
          id: String.t(),
          stop_name: String.t(),
          route_short_name: String.t(),
          route_id: String.t(),
          destination: String.t(),
          direction_id: 0 | 1 | nil,
          time: DateTime.t(),
          inline_badges: list(map())
        }

  def fetch(query_params, opts \\ %{}) do
    case Map.get(opts, :include_schedules, false) do
      true -> fetch_predictions_and_schedules(query_params)
      false -> fetch_predictions_only(query_params)
    end
  end

  defp fetch_predictions_only(query_params) do
    query_params
    |> Prediction.fetch()
    |> from_predictions()
  end

  defp fetch_predictions_and_schedules(query_params) do
    predictions = Prediction.fetch(query_params)
    schedules = Schedule.fetch(query_params)
    merge_predictions_and_schedules(predictions, schedules)
  end

  defp merge_predictions_and_schedules({:ok, predictions}, {:ok, schedules}) do
    predicted_trip_ids =
      predictions
      |> Enum.reject(&is_nil(&1.trip))
      |> Enum.map(& &1.trip.id)
      |> Enum.into(MapSet.new())

    unpredicted_schedules =
      Enum.reject(schedules, fn %{trip: %{id: trip_id}} -> trip_id in predicted_trip_ids end)

    {:ok, predicted_departures} = from_predictions({:ok, predictions})
    {:ok, scheduled_departures} = from_schedules({:ok, unpredicted_schedules})

    merged =
      (predicted_departures ++ scheduled_departures)
      |> Enum.sort_by(& &1.time)

    {:ok, merged}
  end

  defp merge_predictions_and_schedules(_, _), do: :error

  def from_schedules({:ok, schedules}) do
    departures =
      schedules
      |> Enum.reject(&departure_in_past/1)
      |> Enum.map(&from_prediction_or_schedule/1)

    {:ok, departures}
  end

  def from_schedules(:error), do: :error

  def from_prediction_or_schedule(%{
        id: id,
        stop: %{name: stop_name},
        route: %{id: route_id, short_name: route_short_name},
        trip: %{headsign: destination, direction_id: direction_id},
        arrival_time: arrival_time,
        departure_time: departure_time
      }) do
    time = select_prediction_time(arrival_time, departure_time)

    %Screens.Departures.Departure{
      id: id,
      stop_name: stop_name,
      route_short_name: route_short_name,
      route_id: route_id,
      destination: destination,
      direction_id: direction_id,
      time: DateTime.to_iso8601(time),
      inline_badges: []
    }
  end

  def from_prediction_or_schedule(%{
        id: id,
        stop: %{name: stop_name},
        route: %{id: route_id, short_name: route_short_name},
        trip: nil,
        arrival_time: arrival_time,
        departure_time: departure_time
      }) do
    time = select_prediction_time(arrival_time, departure_time)

    %Screens.Departures.Departure{
      id: id,
      stop_name: stop_name,
      route_short_name: route_short_name,
      route_id: route_id,
      destination: nil,
      time: DateTime.to_iso8601(time),
      inline_badges: []
    }
  end

  def from_predictions({:ok, predictions}) do
    departures =
      predictions
      |> Enum.reject(fn %{departure_time: departure_time} -> is_nil(departure_time) end)
      |> Enum.reject(&departure_in_past/1)
      |> Prediction.deduplicate_combined_routes()
      |> Enum.map(&from_prediction_or_schedule/1)

    {:ok, departures}
  end

  def from_predictions(:error), do: :error

  def select_prediction_time(arrival_time, departure_time) do
    case {arrival_time, departure_time} do
      {nil, t} -> t
      {_, nil} -> nil
      {t, _} -> t
    end
  end

  def to_map(d) do
    %{
      id: d.id,
      route: d.route_short_name,
      route_id: d.route_id,
      destination: d.destination,
      direction_id: d.direction_id,
      time: d.time,
      inline_badges: d.inline_badges
    }
  end

  def departure_in_past(%{departure_time: departure_time}) do
    DateTime.compare(departure_time, DateTime.utc_now()) == :lt
  end

  def associate_alerts_with_departures(departures, alerts) do
    delay_map = Screens.Alerts.Alert.build_delay_map(alerts)
    Enum.map(departures, &update_departure_with_delay_alert(delay_map, &1))
  end

  defp update_departure_with_delay_alert(delay_map, %{route_id: route_id} = departure) do
    case delay_map do
      %{^route_id => severity} ->
        %{departure | inline_badges: [%{type: :delay, severity: severity}]}

      _ ->
        departure
    end
  end
end
