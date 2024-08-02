defmodule Screens.Streams.Alerts do
  @moduledoc """
  Supervisor for streamed producer and consumer(s) of Alerts data from the
  V3 API
  """
  use Supervisor

  @dialyzer {:nowarn_function, children: 1}
  @env Mix.env()

  def start_link(opts) do
    {name, init_arg} = Keyword.pop(opts, :name, __MODULE__)
    Supervisor.start_link(__MODULE__, init_arg, name: name)
  end

  @impl true
  def init(_init_arg) do
    children()
    |> Supervisor.init(strategy: :one_for_all)
  end

  defp children(env \\ @env)
  defp children(:test), do: []

  defp children(_env) do
    api_url = Application.get_env(:screens, :api_v3_url)
    api_key = Application.get_env(:screens, :api_v3_key)

    url =
      api_url
      |> URI.merge("/alerts")
      |> URI.to_string()

    producer = {
      ServerSentEventStage,
      name: Screens.Streams.Alerts.Producer, url: url, headers: [{"x-api-key", api_key}]
    }

    consumer = {
      Screens.Alerts.Cache,
      name: Screens.Alerts.Cache, subscribe_to: [Screens.Streams.Alerts.Producer]
    }

    [producer, consumer]
  end
end
