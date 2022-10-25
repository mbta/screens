defprotocol Screens.V2.AlertWidgetInstance do
  @type alert_id :: String.t()

  @doc "Gets the ID of the alert that this widget shows."
  @spec alert_id(t) :: alert_id()
  def alert_id(widget)
end
