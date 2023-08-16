defmodule Screens.V2.CandidateGenerator.Widgets.TrainCrowding do
  @moduledoc false

  alias Screens.Alerts.Alert
  alias Screens.Config.Screen
  alias Screens.Config.V2.{TrainCrowding, Triptych}
  alias Screens.Predictions.Prediction
  alias Screens.Stops.Stop
  alias Screens.V2.Departure
  alias Screens.V2.LocalizedAlert
  alias Screens.V2.WidgetInstance.TrainCrowding, as: CrowdingWidget

  @spec crowding_widget_instances(Screen.t()) :: list(CrowdingWidget.t())
  def crowding_widget_instances(
        config,
        now \\ DateTime.utc_now(),
        fetch_alerts_fn \\ &Alert.fetch_or_empty_list/1
      )

  def crowding_widget_instances(
        %Screen{app_params: %Triptych{train_crowding: %TrainCrowding{enabled: false}}},
        _,
        _
      ) do
    []
  end

  def crowding_widget_instances(
        %Screen{app_params: %Triptych{train_crowding: train_crowding}} = config,
        now,
        fetch_alerts_fn
      ) do
    with params = %{
           direction_id: train_crowding.direction_id,
           route_ids: [train_crowding.route_id],
           stop_ids: [train_crowding.station_id]
         },
         {:ok, predictions} <- Prediction.fetch(params),
         next_train <- List.first(predictions),
         {:ok, location_context} <-
           Stop.fetch_location_context(Triptych, train_crowding.station_id, now) do
      # If no predictions, then no widget
      next_station_for_train =
        if next_train do
          next_train
          |> Departure.stop_for_vehicle()
          |> Stop.fetch_parent_stop_id()
        else
          nil
        end

      alerts =
        params
        |> Map.to_list()
        |> fetch_alerts_fn.()

      # If the train is headed to or stopped at this station, show the widget...
      # UNLESS we're at a temporary terminal
      if next_station_for_train == train_crowding.station_id and
           !any_alert_makes_this_a_terminal?(alerts, location_context) do
        [
          %CrowdingWidget{
            screen: config,
            prediction: next_train,
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

  # TODO: This isn't the first time we've written a temporary_terminal function, but this one
  # is a little more reusable? Consider using this func in other places
  defp temporary_terminal?(localized_alert) do
    localized_alert.alert.effect in [:suspension, :shuttle] and
      LocalizedAlert.location(localized_alert) in [:boundary_downstream, :boundary_upstream]
  end
end
