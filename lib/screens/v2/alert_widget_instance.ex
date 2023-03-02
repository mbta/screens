defprotocol Screens.V2.AlertWidgetInstance do
  @type alert_id :: String.t()

  @doc "Gets the ID(s) of the alert(s) that this widget shows."
  @spec alert_ids(t) :: list(alert_id())
  def alert_ids(widget)
end
