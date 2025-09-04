defmodule Screens.ScreensByAlert.SelfRefreshRunner do
  @moduledoc """
  Simulates regular data requests for screens that are not issuing requests normally.

  The main purpose of this is to ensure `ScreensByAlert` data consumed by Screenplay remains
  accurate in non-production environments (where there are no "real" screens making requests) or
  when real screen hardware is temporarily offline.
  """

  alias __MODULE__.TaskSupervisor
  alias ScreensConfig.Screen

  require Logger

  import Screens.Inject

  use GenServer

  ### Client

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  ### Server

  @batch_size Application.compile_env!(:screens, [__MODULE__, :batch_size])
  @max_concurrency Application.compile_env!(:screens, [__MODULE__, :concurrency])
  @screens_by_alert injected(Screens.ScreensByAlert)
  @screen_data injected(Screens.V2.ScreenData)

  # aim to refresh screens a few seconds before their alert info is deemed stale
  @outdated_threshold_secs Application.compile_env!(:screens, [
                             :screens_by_alert,
                             :screens_by_alert_ttl_seconds
                           ]) - 5

  @empty_set MapSet.new()

  @impl true
  def init(:ok) do
    schedule_check()
    {:ok, @empty_set}
  end

  @impl true
  def handle_info(:check, refreshing_ids) when refreshing_ids == @empty_set do
    now = System.system_time(:second)

    # Select the N "most outdated" screen IDs, sorted by how outdated they are, for refreshing
    {ids_to_refresh, rest_ids} =
      relevant_screen_ids()
      |> @screens_by_alert.get_screens_last_updated()
      |> Enum.filter(fn {_screen_id, timestamp} -> now - timestamp > @outdated_threshold_secs end)
      |> Enum.sort_by(fn {_screen_id, timestamp} -> timestamp end)
      |> Enum.map(fn {screen_id, _timestamp} -> screen_id end)
      |> Enum.split(@batch_size)

    _ = start_refresh(ids_to_refresh, rest_ids)
    schedule_check()

    # Keep track of which screens we have queued for a refresh
    {:noreply, MapSet.new(ids_to_refresh)}
  end

  def handle_info(:check, refreshing_ids) do
    # Set is non-empty; still waiting for some refreshes in progress
    schedule_check()
    {:noreply, refreshing_ids}
  end

  # Screen refresh completed or crashed
  def handle_info({:done, id}, refreshing_ids), do: {:noreply, MapSet.delete(refreshing_ids, id)}

  defp start_refresh([], _rest_ids), do: :ignore

  defp start_refresh(ids, rest_ids) do
    Logger.info(
      "self_refresh_running screen_ids=#{Enum.join(ids, ",")} remaining_count=#{length(rest_ids)}"
    )

    runner = self()

    # Simulate a screen data request (and discard the result) for each ID. Using `async_stream`
    # for the built-in concurrency and timeout controls, within a separate unlinked task so this
    # server doesn't have to wait for all requests to be started before it returns from message
    # handling.
    {:ok, _pid} =
      Task.Supervisor.start_child(TaskSupervisor, fn ->
        TaskSupervisor
        |> Task.Supervisor.async_stream_nolink(
          ids,
          fn id -> tap(id, &@screen_data.get(&1, update_visible_alerts?: true)) end,
          max_concurrency: @max_concurrency,
          on_timeout: :kill_task,
          ordered: false,
          timeout: 10_000,
          zip_input_on_exit: true
        )
        |> Enum.each(fn
          # We don't care whether the simulated request succeeds, crashes, or times out, just that
          # the relevant screen ID is now eligible for another refresh
          {:ok, id} -> send(runner, {:done, id})
          {:exit, {id, _reason}} -> send(runner, {:done, id})
        end)
      end)
  end

  defp relevant_screen_ids do
    Screens.Config.Cache.screen_ids(fn {_id, %Screen{hidden_from_screenplay: hidden}} ->
      not hidden
    end)
  end

  defp schedule_check, do: Process.send_after(self(), :check, 1_000)
end
