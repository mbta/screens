defmodule Screens.Config.Backup.Runner do
  @moduledoc """
  Periodically runs a screen config backup. This is wrapped in `Highlander` (see
  `Screens.Application`) so that it only ever runs on one node in the cluster at a time.

  Since we never need to maintain any state between runs, this is a task supervised by a
  `Task.Supervisor` rather than a `GenServer`.

  Captures the latest backup on a short time frame for syncing between environments and
  a daily backup that we can use for rollbacks on a longer scale.
  """

  alias __MODULE__.TaskSupervisor
  alias Screens.Config.Backup

  @daily_interval Application.compile_env!(:screens, [Backup, :interval_ms])
  @latest_interval :timer.hours(24)

  def child_spec(opts) do
    %{
      id: TaskSupervisor,
      start: {__MODULE__, :start_link, [opts]}
    }
  end

  def start_link(_opts) do
    with {:ok, task_supervisor} <- Task.Supervisor.start_link(name: TaskSupervisor),
         {:ok, _latest_task} <-
           Task.Supervisor.start_child(task_supervisor, &run_latest/0, restart: :permanent),
         {:ok, _daily_task} <-
           Task.Supervisor.start_child(task_supervisor, &run_daily/0, restart: :permanent) do
      {:ok, task_supervisor}
    end
  end

  defp run_latest do
    Process.sleep(@latest_interval)

    case Backup.capture_latest() do
      {:error, reason} -> Logster.error(["screen_configs_backup_error", error: inspect(reason)])
      _ -> :ok
    end

    run_latest()
  end

  defp run_daily do
    case Backup.capture_daily() do
      {:error, reason} ->
        Logster.error(["screen_configs_daily_backup_error", error: inspect(reason)])

      _ ->
        :ok
    end

    Process.sleep(@daily_interval)

    run_daily()
  end
end
