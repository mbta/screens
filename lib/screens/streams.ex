defmodule Screens.Streams do
  @moduledoc """
  `Supervisor` for all V3 API server sent event streams `GenStage` pipelines.

  Each child should be an entire `GenStage` pipeline in its own `Supervisor`
  using the `:rest_for_one` strategy. This allows a crashed stages to be
  restarted in their subscription order.
  """
  use Supervisor

  def start_link(opts) do
    {name, init_arg} = Keyword.pop(opts, :name, __MODULE__)
    Supervisor.start_link(__MODULE__, init_arg, name: name)
  end

  @impl true
  def init(_init_arg) do
    children = [
      Screens.Streams.Alerts
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
