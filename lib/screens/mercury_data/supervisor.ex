defmodule Screens.MercuryData.Supervisor do
  @moduledoc false

  alias Screens.MercuryData.State

  use Supervisor

  def start_link([]) do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    children = [
      %{id: State, start: {State, :start_link, [[name: State]]}}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
