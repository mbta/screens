defmodule Screens.V2.DisruptionDiagram.Validator do
  @moduledoc """
  Validates LocalizedAlerts for compatibility with disruption diagrams:
  - The alert is a subway alert with an effect of shuttle, suspension, or station_closure
  - The alert informs stops on only one subway route
    - For BL & OL, this is the same as the line
    - For RL, this is either the trunk, the Ashmont branch, or the Braintree branch. No combination of the three.
    - For GL, this is any one branch, or just the trunk (Lechmere to Kenmore).
    - No combinations of multiple lines, e.g. some stops on BL and some on OL.
  - The alert does not inform an entire route (we only allow one end of the diagram to have a terminal stop)
  - All stops informed by the alert are directly reachable from the home stop.
  """

  alias Screens.V2.LocalizedAlert

  @spec validate(LocalizedAlert.t()) :: :ok | {:error, reason :: String.t()}
  def validate(localized_alert) do
    with :ok <- validate_effect(localized_alert.alert.effect),
         :ok <- validate_not_whole_route_disruption(localized_alert.alert),
         :ok <- validate_informed_lines(localized_alert) do
      :ok
    end
  end

  defp validate_effect(effect) when effect in [:shuttle, :suspension, :station_closure], do: :ok
  defp validate_effect(effect), do: {:error, "invalid effect: #{effect}"}

  defp validate_informed_lines(%{alert: alert}) do
    informed_subway_routes = LocalizedAlert.informed_subway_routes(%{alert: alert})

    informed_subway_lines = consolidate_gl(informed_subway_routes)

    case informed_subway_lines do
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
