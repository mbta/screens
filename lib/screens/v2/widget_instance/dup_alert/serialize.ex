defmodule Screens.V2.WidgetInstance.DupAlert.Serialize do
  @moduledoc """
  Functions to serialize data for the DUP alert widget.
  """

  alias Screens.V2.WidgetInstance.DupAlert
  alias Screens.V2.WidgetInstance.Common.BaseAlert

  @spec route_color(DupAlert.t()) :: :red | :orange | :green | :blue | :yellow
  def route_color(t) do
    informed_routes = BaseAlert.informed_routes_at_home_stop(t)

    if MapSet.size(informed_routes) == 1 do
      case Enum.at(informed_routes, 0) do
        "Red" -> :red
        "Orange" -> :orange
        "Green" <> _ -> :green
        "Blue" -> :blue
      end
    else
      :yellow
    end
  end

  def remedy_icon(_t) do
  end

  def issue_free_text(_t) do
  end

  def remedy_free_text(_t) do
  end

  def partial_alert_free_text(_t) do
  end
end
