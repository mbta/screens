defmodule Screens.V2.WidgetInstance.SubwayStatus.Serialize.RedLine do
  @moduledoc """
  Red Line specific serialization logic for the Subway Status widget.
  """

  alias Screens.V2.WidgetInstance.SubwayStatus.Serialize
  alias Screens.V2.WidgetInstance.SubwayStatus.Serialize.RoutePill

  def serialize_rl_alerts(grouped_alerts, serialize_alert_rows_for_route_fn) do
    red_alerts = Map.get(grouped_alerts, "Red", [])
    mattapan_alerts = Map.get(grouped_alerts, "Mattapan", [])

    cond do
      # Serialize a row for RL and for Mattapan branch
      !Enum.empty?(red_alerts) and !Enum.empty?(mattapan_alerts) ->
        serialize_red_and_mattapan(red_alerts, mattapan_alerts)

      !Enum.empty?(mattapan_alerts) ->
        serialize_mattapan_only(grouped_alerts)

      true ->
        serialize_alert_rows_for_route_fn.("Red")
    end
  end

  defp serialize_mattapan_only(grouped_alerts) do
    # Serialzes row(s) for the Mattapan branch
    mattapan_alerts = Map.get(grouped_alerts, "Mattapan", [])

    if length(mattapan_alerts) < 3 do
      %{
        type: :contracted,
        alerts: Enum.map(mattapan_alerts, &serialize_red_line_branch_alert/1)
      }
    else
      %{
        type: :contracted,
        alerts: [
          Serialize.serialize_alert_summary(
            length(mattapan_alerts),
            RoutePill.serialize_rl_mattapan_pill()
          )
        ]
      }
    end
  end

  defp serialize_red_and_mattapan(red_alerts, mattapan_alerts) do
    # Returns one row for Red Line and one row for the Mattapan branch
    red_count = length(red_alerts)
    mattapan_count = length(mattapan_alerts)

    serialized_red =
      if red_count == 1 do
        Serialize.serialize_alert_with_route_pill(List.first(red_alerts), "Red")
      else
        Serialize.serialize_alert_summary(red_count, RoutePill.serialize_route_pill("Red"))
      end

    serialized_mattapan =
      if mattapan_count == 1 do
        serialize_red_line_branch_alert(List.first(mattapan_alerts))
      else
        Serialize.serialize_alert_summary(mattapan_count, RoutePill.serialize_rl_mattapan_pill())
      end

    %{
      type: :contracted,
      alerts: [serialized_red, serialized_mattapan]
    }
  end

  defp serialize_red_line_branch_alert(alert) do
    Map.merge(
      %{route_pill: RoutePill.serialize_rl_mattapan_pill()},
      Serialize.serialize_alert(alert, "Mattapan")
    )
  end
end
