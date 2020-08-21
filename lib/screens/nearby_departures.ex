defmodule Screens.NearbyDepartures do
  @moduledoc false

  alias Screens.Config.{Gl, State}

  def by_screen_id(screen_id) do
    %Gl{nearby_departures: nearby_departure_stop_ids} = State.app_params(screen_id)

    prediction_result =
      Screens.Predictions.Prediction.fetch(%{stop_ids: nearby_departure_stop_ids})

    case prediction_result do
      {:ok, predictions} ->
        predictions
        |> Enum.group_by(& &1.stop.id)
        |> Enum.map(fn {stop_id, prediction_list} ->
          {stop_id, select_earliest_prediction(prediction_list)}
        end)
        |> Enum.map(fn {_stop_id, prediction} -> format_prediction(prediction) end)

      :error ->
        []
    end
  end

  defp select_earliest_prediction(prediction_list) do
    case Enum.reject(prediction_list, &is_nil(&1.departure_time)) do
      [] -> nil
      predictions -> Enum.min_by(predictions, & &1.departure_time)
    end
  end

  defp format_prediction(%{
         arrival_time: arrival_time,
         departure_time: departure_time,
         stop: %{name: stop_name},
         route: %{short_name: route},
         trip: %{headsign: destination}
       }) do
    time = Screens.Departures.Departure.select_prediction_time(arrival_time, departure_time)

    %{
      stop_name: stop_name,
      route: route,
      time: time,
      destination: destination
    }
  end

  defp format_prediction(_), do: nil
end
