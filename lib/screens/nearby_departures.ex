defmodule Screens.NearbyDepartures do
  @moduledoc false

  alias Screens.Config.{Gl, State}

  def by_screen_id(screen_id) do
    if State.mode_disabled?(:bus) do
      []
    else
      by_enabled_screen_id(screen_id)
    end
  end

  defp by_enabled_screen_id(screen_id) do
    %Gl{nearby_departures: nearby_departure_stop_ids} = State.app_params(screen_id)

    prediction_result =
      Screens.Predictions.Prediction.fetch(%{stop_ids: nearby_departure_stop_ids})

    case prediction_result do
      {:ok, predictions} ->
        predictions
        |> Enum.group_by(& &1.stop.id)
        |> Enum.map(fn {stop_id, prediction_list} ->
          {stop_id, Enum.min_by(prediction_list, & &1.departure_time, DateTime, fn -> nil end)}
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
