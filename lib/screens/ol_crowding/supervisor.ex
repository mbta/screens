defmodule Screens.OlCrowding.DynamicSupervisor do
  @moduledoc false

  use DynamicSupervisor
  alias Screens.OlCrowding.Logger

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_logger(
        original_crowding_levels,
        prediction,
        %{
          is_real_screen: true,
          screen_id: screen_id,
          triptych_pane: triptych_pane
        },
        train_crowding_config,
        fetch_predictions_fn,
        fetch_parent_stop_id_fn,
        fetch_params
      ) do
    spec = %{
      id: Logger,
      start:
        {Logger, :start_link,
         [
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
           }
         ]}
    }

    DynamicSupervisor.start_child(__MODULE__, spec)
  end
end
