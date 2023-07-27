defmodule Screens.V2.DisruptionDiagram.Validator do
  @moduledoc """
  Validates LocalizedAlerts for compatibility with disruption diagrams:
  - The alert is a subway alert with an effect of shuttle, suspension, or station_closure
  - The alert informs stops on only one subway route
    - For BL & OL, this is the same as the line
    - For RL, this is either the trunk, the Ashmont branch, or the Braintree branch. No combination of the three.
    - For GL, this is any one branch, or just the trunk (Lechmere to Kenmore).
  - The alert does not inform the entire line (we only allow one end of the diagram to have a terminal stop)
  - The current ("home") station is on the line that the alert informs
    - For cases where the home station is on a branch, the alert must only inform stops
      reachable from that branch without transfers. For example, if the home station is
      Cleveland Circle (C branch), the alert must only inform stops between Cleveland Circle and Government Center.
  """

  alias Screens.V2.LocalizedAlert

  require Logger

  def validate(localized_alert) do
    with :ok <- validate_effect(localized_alert.alert.effect),
         :ok <- validate_not_whole_line_disruption(localized_alert.alert),
         :ok <- validate_informed_lines(localized_alert) do
      :ok
    else
      {:error, reason} ->
        Logger.error("[disruption diagram bad args] reason=\"#{reason}\"")
        :error
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

  defp validate_not_whole_line_disruption(alert) do
    if Enum.any?(
         alert.informed_entities,
         &match?(%{route: route_id, direction_id: nil, stop: nil} when is_binary(route_id), &1)
       ),
       do: {:error, "alert informs an entire line"},
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
