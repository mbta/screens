defmodule Screens.OlCrowding.Logger do
  @moduledoc false

  require Logger
  use GenServer

  alias Screens.Predictions.Prediction

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl true
  def init(state) do
    schedule_run()

    {:ok, state}
  end

  @impl true
  def handle_info(
        :run,
        %{
          prediction: prediction,
          logging_options: %{
            is_real_screen: true,
            screen_id: screen_id,
            triptych_pane: triptych_pane
          },
          train_crowding_config: train_crowding_config,
          fetch_predictions_fn: fetch_predictions_fn,
          fetch_parent_stop_id_fn: fetch_parent_stop_id_fn,
          fetch_params: fetch_params
        } = state
      ) do
    schedule_run()

    {:ok, predictions} = fetch_predictions_fn.(fetch_params)
    next_train_prediction = List.first(predictions)
    crowding_levels = Enum.map_join(prediction.vehicle.carriages, ",", & &1.occupancy_status)

    if Prediction.vehicle_status(next_train_prediction) != :stopped_at and
         next_train_prediction |> Prediction.stop_for_vehicle() |> fetch_parent_stop_id_fn.() ==
           train_crowding_config.station_id do
      Logger.info(
        "[train_crowding car_crowding_accuracy_info] screen_id=#{screen_id} triptych_pane=#{triptych_pane} trip_id=#{prediction.trip.id} car_crowding_levels=#{crowding_levels}"
      )

      {:noreply, state}
    else
      Logger.info(
        "[train_crowding car_crowding_accuracy_info] screen_id=#{screen_id} triptych_pane=#{triptych_pane} trip_id=#{prediction.trip.id} car_crowding_levels=#{crowding_levels}"
      )

      {:stop, :shutdown, state}
    end
  end

  defp schedule_run do
    Process.send_after(self(), :run, 5000)
  end
end
