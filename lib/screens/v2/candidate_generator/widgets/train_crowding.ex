defmodule Screens.V2.CandidateGenerator.Widgets.TrainCrowding do
  @moduledoc false

  alias Screens.Config.Screen
  alias Screens.Config.V2.Triptych
  alias Screens.Predictions.Prediction
  alias Screens.Stops.Stop
  alias Screens.V2.Departure
  alias Screens.V2.WidgetInstance.TrainCrowding, as: CrowdingWidget

  @spec crowding_widget_instances(Screen.t()) :: list(CrowdingWidget.t())
  def crowding_widget_instances(
        %Screen{app_params: %Triptych{train_crowding: train_crowding}} = config,
        now \\ DateTime.utc_now()
      ) do
    with params = %{
          direction_id: train_crowding.direction_id,
          route_ids: [train_crowding.route_id],
          stop_ids: [train_crowding.station_id]
         },
         {:ok, predictions} <- Prediction.fetch(params) do

      next_train = hd(predictions)
      
      next_station_for_train = next_train
      |> Departure.stop_for_vehicle()
      |> Stop.fetch_parent_stop_id()

      # If the predicted arrival is sooner than 2 minutes away...
      # next_train_arrival = Departure.select_arrival_time(next_train)
      # if DateTime.compare(next_train_arrival, DateTime.add(now, 2, :minute)) != :gt do

      if next_station_for_train == train_crowding.station_id do
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

end
