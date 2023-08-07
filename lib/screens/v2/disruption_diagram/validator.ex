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
          route in ~w[Blue Orange Red Green-B Green-C Green-D Green-E],
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
    localized_alert.alert
    |> Alert.informed_subway_routes()
    |> consolidate_gl()
    |> case do
      [_single_line] -> :ok
      _ -> {:error, "alert does not inform exactly one subway line"}
    end
  end

  defp validate_not_whole_route_disruption(alert) do
    if Enum.any?(
         alert.informed_entities,
         &match?(%{route: route_id, stop: nil} when is_binary(route_id), &1)
       ),
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
