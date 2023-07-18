defmodule Screens.V2.DisruptionDiagram.Model.Validator do
  @moduledoc """
  Validates LocalizedAlerts for compatibility with disruption diagrams:
  - The alert is a subway alert with an effect of shuttle, suspension, or station_closure
  - The alert informs stops on only one subway line
  - The alert does not inform the entire line (we only allow one end of the diagram to have a terminal stop)
  - The current ("home") station is on the line that the alert informs
  """

  alias Screens.V2.LocalizedAlert

  require Logger

  def validate(localized_alert) do
    with :ok <- validate_effect(localized_alert.alert.effect),
         :ok <- validate_not_whole_line_disruption(localized_alert.alert),
         {:ok, informed_subway_routes} <- validate_informed_lines(localized_alert),
         :ok <-
           validate_home_stop_on_informed_line(
             localized_alert.location_context.routes,
             informed_subway_routes
           ) do
      :ok
    else
      {:error, reason} ->
        Logger.error("[disruption diagram bad args] reason=\"#{reason}\"")
        :error
    end
  end

  defp validate_effect(effect) when effect in [:shuttle, :suspension, :station_closure], do: :ok
  defp validate_effect(effect), do: {:error, "invalid effect: #{effect}"}

  defp validate_informed_lines(localized_alert) do
    informed_subway_routes = LocalizedAlert.informed_subway_routes(localized_alert)

    informed_subway_lines = consolidate_gl(informed_subway_routes)

    case informed_subway_lines do
      [_single_line] -> {:ok, informed_subway_routes}
      _ -> {:error, "alert does not inform exactly one subway line"}
    end
  end

  defp validate_not_whole_line_disruption(alert) do
    if Enum.any?(
         alert.informed_entities,
         &match?(%{route: route_id, direction_id: nil, stop: nil} when is_binary(route_id), &1)
       ),
       do: {:error, "alert informs an entire line"},
       else: :ok
  end

  defp validate_home_stop_on_informed_line(routes_at_home_stop, informed_subway_routes) do
    if Enum.any?(routes_at_home_stop, &(&1.route_id in informed_subway_routes)),
      do: :ok,
      else: {:error, "alert does not inform a subway line that serves screen's home stop"}
  end

  defp consolidate_gl(route_ids) do
    route_ids
    |> Enum.map(fn
      "Green" <> _ -> "Green"
      other -> other
    end)
    |> Enum.uniq()
  end
end
