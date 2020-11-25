defmodule Screens.GdsData.Supervisor do
  @moduledoc false

  use Supervisor

  def start_link([]) do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    children = [
      worker(Screens.GdsData.State, [[name: Screens.GdsData.State]])
    ]

    supervise(children, strategy: :one_for_one)
  end
end
