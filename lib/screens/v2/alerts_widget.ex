defprotocol Screens.V2.AlertsWidget do
  @moduledoc """
  Protocol for a widget that models zero or more alerts.
  """

  # https://hexdocs.pm/elixir/Protocol.html#module-fallback-to-any
  @fallback_to_any true

  @type alert_id :: String.t()

  @doc "Gets the ID(s) of the alert(s) that this widget shows."
  @spec alert_ids(t) :: list(alert_id())
  def alert_ids(widget)
end

# https://hexdocs.pm/elixir/Protocol.html#module-fallback-to-any
defimpl Screens.V2.AlertsWidget, for: Any do
  def alert_ids(_), do: []
end
