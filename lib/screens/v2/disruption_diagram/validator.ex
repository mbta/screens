defmodule Screens.V2.DisruptionDiagram.Validator do
  @moduledoc """
  Validates LocalizedAlerts for compatibility with disruption diagrams:
  - The alert is a subway alert with an effect of shuttle, suspension, or station_closure.
  - The alert does not inform an entire route.
  - If the alert is a shuttle or suspension, it informs at least 2 stops.
  - All stops informed by the alert are reachable from the home stop without any transfers.
    - in other words, the alert informs stops on only one subway route.
  """

  alias Screens.Alerts.Alert
  alias Screens.Alerts.InformedEntity
  alias Screens.LocationContext
  alias Screens.V2.LocalizedAlert

  @spec validate(LocalizedAlert.t()) :: :ok | {:error, reason :: String.t()}
  def validate(localized_alert) do
    with :ok <- validate_effect(localized_alert.alert.effect),
         :ok <- validate_not_whole_route_disruption(localized_alert.alert),
         :ok <- validate_stop_count(localized_alert.alert) do
      validate_informed_lines(localized_alert)
    end
  end

  defp validate_effect(effect) when effect in [:shuttle, :suspension, :station_closure], do: :ok
  defp validate_effect(effect), do: {:error, "invalid effect: #{effect}"}

  defp validate_stop_count(%{effect: continuous_effect} = alert)
       when continuous_effect in [:shuttle, :suspension] do
    informed_stops =
      for %{stop: stop, route: route} <- alert.informed_entities,
          match?("place-" <> _, stop),
          route in ~w[Blue Orange Red Green-B Green-C Green-D Green-E Mattapan],
          uniq: true,
          do: stop

    if length(informed_stops) >= 2 do
      :ok
    else
      {:error, "#{continuous_effect} alert does not inform at least 2 stops"}
    end
  end

  defp validate_stop_count(_), do: :ok

  defp validate_informed_lines(localized_alert) do
    # We can draw a diagram for an alert only when there's a single line to draw.
    #
    # This is the case when either:
    # - The alert informs only one line, or
    # - The alert informs multiple lines, but only one of those informed lines serves the home stop.

    localized_alert.alert
    |> Alert.informed_subway_routes()
    |> consolidate_gl()
    |> case do
      [_single_line] ->
        :ok

      informed_lines ->
        lines_serving_stop =
          localized_alert.location_context
          |> LocationContext.route_ids()
          |> consolidate_gl()

        informed_lines_serving_stop =
          MapSet.intersection(MapSet.new(informed_lines), MapSet.new(lines_serving_stop))

        if MapSet.size(informed_lines_serving_stop) == 1 do
          :ok
        else
          {:error,
           "alert does not inform exactly one subway line, and home stop location does not help us choose one of the informed lines"}
        end
    end
  end

  defp validate_not_whole_route_disruption(alert) do
    if Enum.any?(alert.informed_entities, &InformedEntity.whole_route?/1),
      do: {:error, "alert informs an entire route"},
      else: :ok
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
