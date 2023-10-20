defmodule Screens.OlCrowding.LogCrowdingInfo do
  @moduledoc false

  require Logger
  use GenServer

  alias Screens.Predictions.Prediction
  alias Screens.Util

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
          original_crowding_levels: original_crowding_levels,
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

    crowding_levels =
      Enum.map_join(
        prediction.vehicle.carriages,
        ",",
        &Util.translate_carriage_occupancy_status/1
      )

    cond do
      # A car's crowding level changed. Log it and shutdown the process.
      original_crowding_levels != crowding_levels ->
        Logger.info(
          "[train_crowding car_crowding_class_change] screen_id=#{screen_id} triptych_pane=#{triptych_pane} trip_id=#{prediction.trip.id} original_crowding_levels=#{original_crowding_levels} car_crowding_levels=#{crowding_levels}"
        )

        {:stop, :shutdown, state}

      # The train is now stopped at the current station and no crowding level changed. Shut down the process without logging.
      Prediction.vehicle_status(next_train_prediction) == :stopped_at and
          next_train_prediction |> Prediction.stop_for_vehicle() |> fetch_parent_stop_id_fn.() ==
            train_crowding_config.station_id ->
        {:stop, :shutdown, state}

      # Still more work to do.
      true ->
        {:noreply, state}
    end
  end

  defp schedule_run do
    Process.send_after(self(), :run, 2000)
  end
end
