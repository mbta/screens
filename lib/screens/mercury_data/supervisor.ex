defmodule Screens.MercuryData.Supervisor do
  @moduledoc false

  use Supervisor

  def start_link([]) do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    children = [
      worker(Screens.MercuryData.State, [[name: Screens.MercuryData.State]])
    ]

    supervise(children, strategy: :one_for_one)
  end
end
