defmodule Screens.TriptychPlayer.State.Supervisor do
  @moduledoc false

  use Supervisor

  def start_link([]) do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    children = [
      {Screens.TriptychPlayer.State, name: Screens.TriptychPlayer.State}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
