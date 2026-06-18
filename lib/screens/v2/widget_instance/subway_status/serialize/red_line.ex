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
      !Enum.empty?(red_alerts) and !Enum.empty?(mattapan_alerts) ->
        # Serialize a row for RL and a row for Mattapan branch
        serialize_red_and_mattapan(red_alerts, mattapan_alerts)

      !Enum.empty?(mattapan_alerts) ->
        # Serialize 1 or 2 rows for the Mattapan branch
        serialize_mattapan_only(grouped_alerts)

      true ->
        # Serialize 1 or 2 rows for the Red Line
        serialize_alert_rows_for_route_fn.("Red")
    end
  end

  defp serialize_mattapan_only(grouped_alerts) do
    grouped_alerts
    |> Map.get("Mattapan", [])
    |> serialize_mattapan_only_station_closures()
  end

  defp serialize_mattapan_only_station_closures([
         %{alert: %{effect: :station_closure}} = alert1,
         %{alert: %{effect: :station_closure}} = alert2
       ]) do
    alert1
    |> Serialize.consolidate_ies_under_one_subway_alert(alert2)
    |> serialize_rl_branch_alert()
    |> then(fn combined_alert ->
      %{
        type: :contracted,
        alerts: [combined_alert]
      }
    end)
  end

  defp serialize_mattapan_only_station_closures(mattapan_alerts)
       when is_list(mattapan_alerts) and length(mattapan_alerts) < 3 do
    %{
      type: :contracted,
      alerts: Enum.map(mattapan_alerts, &serialize_rl_branch_alert/1)
    }
  end

  defp serialize_mattapan_only_station_closures(mattapan_alerts) do
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
        serialize_rl_branch_alert(List.first(mattapan_alerts))
      else
        Serialize.serialize_alert_summary(mattapan_count, RoutePill.serialize_rl_mattapan_pill())
      end

    %{
      type: :contracted,
      alerts: [serialized_red, serialized_mattapan]
    }
  end

  defp serialize_rl_branch_alert(alert) do
    Map.merge(
      %{route_pill: RoutePill.serialize_rl_mattapan_pill()},
      Serialize.serialize_alert(alert, "Mattapan")
    )
  end
end
