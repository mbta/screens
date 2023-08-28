defmodule Screens.V2.CandidateGenerator.Widgets.TrainCrowding do
  @moduledoc false

  alias Screens.Alerts.Alert
  alias Screens.Config.Screen
  alias Screens.Config.V2.{TrainCrowding, Triptych}
  alias Screens.Predictions.Prediction
  alias Screens.Stops.Stop
  alias Screens.V2.LocalizedAlert
  alias Screens.V2.WidgetInstance.TrainCrowding, as: CrowdingWidget

  @spec crowding_widget_instances(Screen.t()) :: list(CrowdingWidget.t())
  def crowding_widget_instances(
        config,
        now \\ DateTime.utc_now(),
        fetch_predictions_fn \\ &Prediction.fetch/1,
        fetch_location_context_fn \\ &Stop.fetch_location_context/3,
        fetch_parent_stop_id_fn \\ &Stop.fetch_parent_stop_id/1,
        fetch_alerts_fn \\ &Alert.fetch/1
      )

  def crowding_widget_instances(
        %Screen{app_params: %Triptych{train_crowding: %TrainCrowding{enabled: false}}},
        _,
        _,
        _,
        _,
        _
      ) do
    []
  end

  def crowding_widget_instances(
        %Screen{app_params: %Triptych{train_crowding: train_crowding}} = config,
        now,
        fetch_predictions_fn,
        fetch_location_context_fn,
        fetch_parent_stop_id_fn,
        fetch_alerts_fn
      ) do
    params = %{
      direction_id: train_crowding.direction_id,
      route_ids: [train_crowding.route_id],
      stop_ids: [train_crowding.station_id]
    }

    with {:ok, predictions} <- fetch_predictions_fn.(params),
         {:ok, location_context} <-
           fetch_location_context_fn.(Triptych, train_crowding.station_id, now),
         {:ok, alerts} <-
           params |> Map.to_list() |> fetch_alerts_fn.() do
      next_train_prediction = List.first(predictions)

      # If there is an upcoming train, it's headed to this station, and we're not at a temporary terminal,
      # show the widget
      if not is_nil(next_train_prediction) and
           Prediction.vehicle_status(next_train_prediction) == :incoming_at and
           next_train_prediction |> Prediction.stop_for_vehicle() |> fetch_parent_stop_id_fn.() ==
             train_crowding.station_id and
           next_train_prediction.vehicle.carriages != [] and
           not any_alert_makes_this_a_terminal?(alerts, location_context) do
        [
          %CrowdingWidget{
            screen: config,
            prediction: next_train_prediction,
            now: now
          }
        ]
      else
        []
      end
    else
      :error -> []
    end
  end

  # Given alerts at this station, check to see if any alert make this a temporary terminal
  defp any_alert_makes_this_a_terminal?(alerts, location_context) do
    Enum.any?(alerts, fn alert ->
      temporary_terminal?(%{alert: alert, location_context: location_context})
    end)
  end

  # credo:disable-for-next-line
  # TODO: This isn't the first time we've written a temporary_terminal function, but this one
  # is a little more reusable? Consider using this func in other places
  defp temporary_terminal?(localized_alert) do
    localized_alert.alert.effect in [:suspension, :shuttle] and
      LocalizedAlert.location(localized_alert) in [:boundary_downstream, :boundary_upstream]
  end
end
