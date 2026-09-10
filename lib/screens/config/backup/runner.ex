defmodule Screens.Config.Backup.Runner do
  @moduledoc """
  Periodically runs a screen config backup. This runs on every instance, but the backup itself is
  guarded by an advisory lock so only one instance does the work for a given interval.

  Since we never need to maintain any state between runs, this is a task supervised by a
  `Task.Supervisor` rather than a `GenServer`.
  """

  alias __MODULE__.TaskSupervisor
  alias Screens.Config.Backup

  @interval Application.compile_env!(:screens, [Backup, :interval_ms])

  def child_spec(opts) do
    %{
      id: TaskSupervisor,
      start: {__MODULE__, :start_link, [opts]}
    }
  end

  def start_link(_opts) do
    with {:ok, task_supervisor} <- Task.Supervisor.start_link(name: TaskSupervisor),
         {:ok, _task} <- Task.Supervisor.start_child(task_supervisor, &run/0, restart: :permanent) do
      {:ok, task_supervisor}
    end
  end

  defp run do
    Process.sleep(@interval)

    case Backup.run() do
      {:error, reason} -> Logster.error(["screen_configs_backup_error", error: inspect(reason)])
      _ -> :ok
    end

    run()
  end
end
