defmodule Screens.Override.Supervisor do
  @moduledoc false

  use Supervisor

  def start_link([]) do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    children = [
      worker(Screens.Override.State, [[name: Screens.Override.State]])
    ]

    supervise(children, strategy: :one_for_one)
  end
end
