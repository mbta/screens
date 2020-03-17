defmodule Screens.NearbyDepartures do
  @moduledoc false

  def by_stop_id(stop_id) do
    nearby_departure_stop_ids =
      :screens
      |> Application.get_env(:nearby_departures)
      |> Map.get(stop_id)

    {:ok, predictions} =
      nearby_departure_stop_ids
      |> Enum.join(",")
      |> Screens.Predictions.Prediction.by_stop_id()

    predictions
    |> Enum.group_by(& &1.stop.id)
    |> Enum.map(fn {stop_id, prediction_list} ->
      {stop_id, Enum.min_by(prediction_list, & &1.time)}
    end)
    |> Enum.map(fn {_stop_id, prediction} -> format_prediction(prediction) end)
  end

  defp format_prediction(%{
         time: time,
         stop: %{name: stop_name},
         route: %{short_name: route},
         trip: %{headsign: destination}
       }) do
    %{
      stop_name: stop_name,
      route: route,
      time: time,
      destination: destination
    }
  end

  defp format_prediction(_), do: nil
end
