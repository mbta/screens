defmodule Screens.OlCrowding.DynamicSupervisor do
  @moduledoc false

  require Logger

  use DynamicSupervisor
  alias Screens.OlCrowding.LogCrowdingInfo

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_logger(
        original_crowding_levels,
        %{
          next_train_prediction: prediction,
          logging_options: logging_options,
          train_crowding_config: train_crowding_config,
          fetch_predictions_fn: fetch_predictions_fn,
          fetch_parent_stop_id_fn: fetch_parent_stop_id_fn,
          fetch_params: fetch_params
        }
      ) do
    spec = %{
      id: LogCrowdingInfo,
      start:
        {LogCrowdingInfo, :start_link,
         [
           %{
             original_crowding_levels: original_crowding_levels,
             prediction: prediction,
             logging_options: logging_options,
             train_crowding_config: train_crowding_config,
             fetch_predictions_fn: fetch_predictions_fn,
             fetch_parent_stop_id_fn: fetch_parent_stop_id_fn,
             fetch_params: fetch_params
           }
         ]},
      restart: :transient
    }

    case DynamicSupervisor.start_child(__MODULE__, spec) do
      {:ok, child_pid} ->
        _ = :timer.exit_after(10_000, child_pid, :kill)

      {:ok, child_pid, _} ->
        _ = :timer.exit_after(10_000, child_pid, :kill)

      {:error, error} ->
        Logger.error("crowding_dyn_supervisor_process_error #{inspect(error)}")

      _ ->
        Logger.warn("Something went wrong with starting the crowding dynamic supervisor process")
    end
  end
end
