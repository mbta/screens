defmodule Screens.Alerts.Cache do
  @moduledoc """
  GenStage Consumer of Alert server sent event data
  """
  use GenStage

  require Logger

  alias Screens.Alerts
  alias ServerSentEventStage.Event

  def start_link(opts) do
    {name, init_arg} = Keyword.pop(opts, :name, __MODULE__)
    GenStage.start_link(__MODULE__, init_arg, name: name)
  end

  @impl true
  def init(init_arg) do
    state = %{}
    subscribe_to = Keyword.get(init_arg, :subscribe_to, [Screens.Streams.Alerts.Producer])
    {:consumer, state, subscribe_to: subscribe_to}
  end

  @impl true
  def handle_events(events, _from, state) do
    state =
      for event <- events, reduce: state do
        state ->
          case decode_data(event) do
            :error -> state
            %Event{} = event -> apply_event(event, state)
          end
      end

    {:noreply, [], state}
  end

  @impl true
  def handle_call(:all, _from, state) do
    {:reply, Map.values(state), [], state}
  end

  def all(pid \\ __MODULE__) do
    GenStage.call(pid, :all)
  end

  defp apply_event(%Event{event: "reset", data: data}, _state) do
    data
    |> Enum.map(fn data ->
      alert = Alerts.Parser.parse_alert(data)
      {alert.id, alert}
    end)
    |> Map.new()
  end

  defp apply_event(%Event{event: event, data: alert}, state) when event in ~w[add update] do
    alert = Alerts.Parser.parse_alert(alert)

    Map.put_new(state, alert.id, alert)
  end

  defp apply_event(%Event{event: "remove", data: %{"id" => id}}, state) do
    Map.delete(state, id)
  end

  defp apply_event(event, state) do
    Logger.warning(fn -> "Unknown event: #{inspect(event)}" end)
    state
  end

  defp decode_data(%Event{data: encoded} = event) do
    case Jason.decode(encoded) do
      {:ok, decoded} -> %{event | data: decoded}
      _ -> :error
    end
  end
end
