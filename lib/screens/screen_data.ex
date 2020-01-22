defmodule Screens.ScreenData do
  @moduledoc false

  def by_stop_id(stop_id) do
    predictions = Screens.Predictions.Prediction.by_stop_id(stop_id)

    %{
      current_time: DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601(),
      stop_name: extract_stop_name_from_predictions(predictions),
      prediction_rows: format_prediction_rows(predictions)
    }
  end

  defp extract_stop_name_from_predictions(predictions) do
    [first_prediction | _] = predictions
    first_prediction.stop.name
  end

  defp format_prediction_rows(predictions) do
    Enum.map(predictions, &format_prediction_row/1)
  end

  defp format_prediction_row(prediction) do
    %{
      route_name: prediction.route.short_name,
      trip_headsign: prediction.trip.headsign,
      time: DateTime.to_iso8601(prediction.time)
    }
  end
end
