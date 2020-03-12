defmodule Screens.Departures.Departure do
  @moduledoc false

  defstruct id: nil,
            stop_name: nil,
            route_short_name: nil,
            route_id: nil,
            destination: nil,
            time: nil,
            inline_badges: nil

  @type t :: %__MODULE__{
          id: String.t(),
          stop_name: String.t(),
          route_short_name: String.t(),
          route_id: String.t(),
          destination: String.t(),
          time: DateTime.t(),
          inline_badges: list(map())
        }

  def by_stop_id(stop_id, route_id, direction_id) do
    case Screens.Predictions.Prediction.by_stop_id(stop_id, route_id, direction_id) do
      {:ok, result} -> {:ok, Enum.map(result, &from_prediction/1)}
      :error -> :error
    end
  end

  def by_stop_id(stop_id) do
    case Screens.Predictions.Prediction.by_stop_id(stop_id) do
      {:ok, result} -> {:ok, Enum.map(result, &from_prediction/1)}
      :error -> :error
    end
  end

  def to_map(d) do
    %{
      id: d.id,
      route: d.route_short_name,
      destination: d.destination,
      time: d.time,
      inline_badges: d.inline_badges
    }
  end

  def from_predictions({:ok, predictions}) do
    {:ok, Enum.map(predictions, &from_prediction/1)}
  end

  def from_predictions(:error), do: :error

  def from_prediction(%{
        id: id,
        stop: %{name: stop_name},
        route: %{id: route_id, short_name: route_short_name},
        trip: %{headsign: destination},
        time: time
      }) do
    %Screens.Departures.Departure{
      id: id,
      stop_name: stop_name,
      route_short_name: route_short_name,
      route_id: route_id,
      destination: destination,
      time: DateTime.to_iso8601(time),
      inline_badges: []
    }
  end

  def from_prediction(%{
        id: id,
        stop: %{name: stop_name},
        route: %{id: route_id, short_name: route_short_name},
        trip: nil,
        time: time
      }) do
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
