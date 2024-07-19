defprotocol Screens.V2.SingleAlertWidget do
  @moduledoc """
  Protocol for a widget that models exactly one alert.

  This includes but is not limited to:
  - `Screens.V2.WidgetInstance.Alert`
  - `Screens.V2.WidgetInstance.ReconstructedAlert`
  - `Screens.V2.WidgetInstance.DupAlert`
  """

  alias Screens.Alerts.Alert
  alias ScreensConfig.Screen
  alias Screens.RouteType

  @type alert_id :: String.t()
  @type stop_id :: String.t()
  @type route_id :: String.t()

  @doc """
  Gets the Screens.Alerts.Alert struct that this widget contains.
  """
  @spec alert(t()) :: Alert.t()
  def alert(widget)

  @doc """
  Gets the ScreensConfig.Screen struct describing the screen that this widget appears on.
  """
  @spec screen(t()) :: Screen.t()
  def screen(widget)

  @doc """
  Gets the home stop ID of this widget, usually from screen configuration.

  **The stop ID should be in the same format as the stop sequences--either parent station ID or child stop ID.**
  """
  @spec home_stop_id(t()) :: stop_id()
  def home_stop_id(widget)

  @doc """
  Gets the list of routes that serve this widget's home stop.
  """
  @spec routes_at_stop(t()) ::
          list(%{route_id: route_id(), active?: boolean(), type: RouteType.t()})
  def routes_at_stop(widget)

  @doc """
  """
  @spec stop_sequences(t()) :: list(list(stop_id()))
  def stop_sequences(widget)

  @doc """
  Gets the headsign matchers mapping for this widget, or nil if headsigns are not used.
  """
  @spec headsign_matchers(t()) :: %{stop_id() => list(tuple())} | nil
  def headsign_matchers(widget)
end
