defmodule Screens.Health do
  @moduledoc false

  use GenServer
  require Logger

  @process_health_interval_ms 300_000
  @process_metrics ~w(memory binary_memory heap_size total_heap_size message_queue_len reductions)a

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl true
  def init(_) do
    {:ok, _timer_ref} = :timer.send_interval(@process_health_interval_ms, self(), :process_health)

    {:ok, nil}
  end

  @impl true
  def handle_info(:process_health, state) do
    diagnostic_processes()
    |> Stream.map(&process_metrics/1)
    |> Enum.each(fn {name, supervisor, metrics} ->
      Logger.info([
        ~c"screens_process_health name=\"#{inspect(name)}\" supervisor=\"#{inspect(supervisor)}\" ",
        metrics
      ])
    end)

    {:noreply, state}
  end

  def handle_info(msg, state) do
    Logger.info("Screens.Health unknown_message msg=#{inspect(msg)}")
    {:noreply, state}
  end

  @type process_info() :: {pid(), name :: term(), supervisor :: term()}

  @spec diagnostic_processes() :: Enumerable.t()
  defp diagnostic_processes do
    [
      Stream.flat_map(
        Supervisor.which_children(Screens.Supervisor),
        &descendants(&1, Screens.Supervisor)
      ),
      top_processes_by(:memory, limit: 20),
      top_processes_by(:binary_memory, limit: 20)
    ]
    |> Stream.concat()
    |> Stream.uniq_by(&elem(&1, 0))
  end

  @spec top_processes_by(atom(), limit: non_neg_integer()) :: Enumerable.t()
  defp top_processes_by(attribute, limit: limit) do
    Stream.map(:recon.proc_count(attribute, limit), &recon_entry/1)
  end

  @spec descendants(
          {name :: term(), child :: Supervisor.child() | :restarting,
           type :: :worker | :supervisor, modules :: [module()] | :dynamic},
          supervisor :: term()
        ) :: nil | [] | [process_info()]
  defp descendants({_name, status, _type, _modules}, _supervisor) when is_atom(status), do: []

  defp descendants({name, pid, :supervisor, _modules}, _supervisor) do
    if Process.alive?(pid) do
      pid |> Supervisor.which_children() |> Stream.flat_map(&descendants(&1, name))
    end
  end

  defp descendants({name, pid, _, _}, supervisor), do: [{pid, name, supervisor}]

  @spec recon_entry(:recon.proc_attrs()) :: process_info()
  defp recon_entry({pid, _count, [name | _]}) when is_atom(name), do: {pid, name, nil}
  defp recon_entry({pid, _count, _info}), do: {pid, nil, nil}

  @spec process_metrics({pid(), term() | nil, term() | nil}) :: {term(), term(), iodata()}
  defp process_metrics({pid, name, supervisor}) do
    metrics =
      pid
      |> :recon.info(@process_metrics)
      |> Stream.map(fn {metric, value} -> "#{metric}=#{value}" end)
      |> Enum.intersperse(" ")

    {name, supervisor, metrics}
  end
end
