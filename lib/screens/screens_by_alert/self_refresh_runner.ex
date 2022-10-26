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

  # Maximum number of screen updates that can happen per run.
  # Assuming a worst case of .5 sec per screen update, a max
  # of 20 has the job take 10 seconds max per run, giving
  # plenty of space to avoid overlapping runs.
  @max_screen_updates_per_run 20

  @screens_ttl_seconds Application.compile_env(:screens, :screens_by_alert)[:screens_ttl_seconds]

  # The job runs at the same rate as screen data expiration from the cache (though these "windows" will be offset from one another)
  @job_run_interval_ms @screens_ttl_seconds * 1_000

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
      |> Enum.filter(fn {_screen_id, timestamp} -> now - timestamp > @screens_ttl_seconds end)
      # sort by age, oldest first
      |> Enum.sort_by(fn {_screen_id, timestamp} -> timestamp end)
      |> Enum.map(fn {screen_id, _timestamp} -> screen_id end)
      |> Enum.split(@max_screen_updates_per_run)

    max_refreshes_per_run_exceeded = match?([_ | _], overflow)

    Logger.info(
      "[running screens_by_alert self refresh] refreshing_screen_ids=#{Enum.join(screen_ids_to_refresh, ",")} max_refreshes_per_run_exceeded=#{max_refreshes_per_run_exceeded}"
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
    for screen_id <- screen_ids_to_refresh do
      _ =
        Task.Supervisor.start_child(TaskSupervisor, fn ->
          @screen_data_fn.(screen_id, skip_serialize: true)
        end)
    end

    {:noreply, state}
  end

  defp schedule_run do
    Process.send_after(self(), :run, @job_run_interval_ms)
  end

  @doc "A fake screen-data-fetching function to be used during tests, to avoid making requests."
  def fake_screen_data_fn(_screen_id, _opts), do: nil
end
