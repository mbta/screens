defmodule Screens.Alerts.Cache do
  @moduledoc """
  GenStage Consumer of Alert server sent event data
  """
  use GenStage

  require Logger

  alias Screens.Alerts
  alias ServerSentEventStage.Event

  @table __MODULE__

  defstruct [:table]

  def start_link(opts) do
    {name, init_arg} = Keyword.pop(opts, :name, __MODULE__)
    GenStage.start_link(__MODULE__, init_arg, name: name)
  end

  @impl true
  def init(init_arg) do
    subscribe_to = Keyword.get(init_arg, :subscribe_to, [Screens.Streams.Alerts.Producer])

    table = @table

    ^table =
      :ets.new(table, [:named_table, :set, read_concurrency: true, write_concurrency: false])

    state = %__MODULE__{table: table}

    {:consumer, state, subscribe_to: subscribe_to}
  end

  @impl true
  def handle_events(events, _from, state) do
    events
    |> Enum.map(&decode_data/1)
    |> Enum.each(&handle_event(&1, state))

    {:noreply, [], state}
  end

  def all(table \\ @table) do
    table
    |> :ets.tab2list()
    |> Enum.map(&elem(&1, 1))
  end

  defp handle_event(%Event{event: "reset", data: data}, state) do
    alerts =
      Enum.map(data, fn data ->
        alert = Alerts.Parser.parse_alert(data)
        {alert.id, alert}
      end)

    true = :ets.delete_all_objects(state.table)
    true = :ets.insert(state.table, alerts)

    :ok
  end

  defp handle_event(%Event{event: event, data: alert}, state) when event in ~w[add update] do
    alert = Alerts.Parser.parse_alert(alert)

    true = :ets.insert(state.table, {alert.id, alert})

    :ok
  end

  defp handle_event(%Event{event: "remove", data: %{"id" => id}}, state) do
    true = :ets.delete(state.table, id)

    :ok
  end

  defp decode_data(%Event{data: encoded} = event) do
    decoded = Jason.decode!(encoded)

    %{event | data: decoded}
  end
end
