defmodule Screens.ScreensByAlert.SelfRefreshRunner do
  @moduledoc """
  A stateless "job-runner" GenServer that routinely checks for out-of-date
  screen data, and simulates data requests for any that it finds.
  """

  alias Screens.ScreensByAlert

  # (Not a real module--just a name assigned to the Task.Supervisor process that supervises each simulated data request run)
  alias Screens.ScreensByAlert.SelfRefreshRunner.TaskSupervisor

  require Logger
  use GenServer

  ### Client

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  ### Server

  # Maximum number of screen updates that can happen per run
  @max_screen_updates_per_run 30

  # The job should run just slower than the slowest screen client refresh rate (e-ink, 30 sec)
  @job_run_interval_ms 31_000

  @data_ttl_seconds 30

  @screen_data_fn Application.compile_env(:screens, :screens_by_alert)[:screen_data_fn]

  @impl true
  def init(:ok) do
    schedule_run()

    {:ok, nil}
  end

  @impl true
  def handle_info(:run, state) do
    schedule_run()

    now = System.system_time(:second)

    {screen_ids_to_refresh, overflow} =
      Screens.Config.State.v2_screens_visible_to_screenplay()
      # get a mapping from each ID to its last updated time
      |> ScreensByAlert.get_screens_last_updated()
      # filter to outdated IDs
      |> Enum.filter(fn {_screen_id, timestamp} -> now - timestamp > @data_ttl_seconds end)
      # sort by age, oldest first
      |> Enum.sort_by(fn {_screen_id, timestamp} -> timestamp end)
      |> Enum.map(fn {screen_id, _timestamp} -> screen_id end)
      |> Enum.split(@max_screen_updates_per_run)

    Logger.info(
      "[running screens_by_alert self refresh] screen_ids_being_refreshed_now=#{Enum.join(screen_ids_to_refresh, ",")} count_of_remaining_screen_ids_to_refresh=#{length(overflow)}"
    )

    # We don't care about the result of the work, just its side-effect
    # of updating the relevant cached data.
    # In fact, we don't even care if the function call succeeds.
    #
    # Task.Supervisor.start_child/3 lets us run each update concurrently without
    # using the return value, while also providing graceful handling of shutdowns.
    #
    # Doing the work in a separate, unlinked task process protects this GenServer
    # process from going down if an exception is raised while running
    # ScreenData.by_screen_id/1 for some screen.
    Enum.each(screen_ids_to_refresh, fn screen_id ->
      Task.Supervisor.start_child(TaskSupervisor, fn ->
        @screen_data_fn.(screen_id, skip_serialize: true)
      end)
    end)

    {:noreply, state}
  end

  defp schedule_run do
    Process.send_after(self(), :run, @job_run_interval_ms)
  end
end
