defmodule Screens.NearbyDepartures do
  @moduledoc false

  def by_stop_id(stop_id) do
    nearby_departure_stop_ids =
      :screens
      |> Application.get_env(:nearby_departures)
      |> Map.get(stop_id)

    prediction_result =
      nearby_departure_stop_ids
      |> Enum.join(",")
      |> Screens.Predictions.Prediction.by_stop_id()

    case prediction_result do
      {:ok, predictions} ->
        predictions
        |> Enum.group_by(& &1.stop.id)
        |> Enum.map(fn {stop_id, prediction_list} ->
          {
            stop_id,
            prediction_list
            |> Enum.reject(&is_nil(&1.departure_time))
            |> Enum.min_by(& &1.departure_time)
          }
        end)
        |> Enum.map(fn {_stop_id, prediction} -> format_prediction(prediction) end)

      :error ->
        []
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
