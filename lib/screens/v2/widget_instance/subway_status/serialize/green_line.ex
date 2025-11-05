defmodule Screens.V2.WidgetInstance.SubwayStatus.Serialize.GreenLine do
  @moduledoc """
  Green Line specific serialization logic for the Subway Status widget.
  """

  alias Screens.Alerts.Alert
  alias Screens.Alerts.InformedEntity
  alias Screens.Stops.Subway
  alias Screens.V2.WidgetInstance.SubwayStatus
  alias Screens.V2.WidgetInstance.SubwayStatus.Serialize
  alias Screens.V2.WidgetInstance.SubwayStatus.Serialize.RoutePill
  alias Screens.V2.WidgetInstance.SubwayStatus.Serialize.Utils

  @green_line_branches ["Green-B", "Green-C", "Green-D", "Green-E"]

  ###################################
  # Green Line Alerts Serialization #
  ###################################

  def serialize_gl_alerts(grouped_alerts, serialize_alert_rows_for_route_fn) do
    green_line_alerts =
      @green_line_branches
      |> Enum.flat_map(fn route -> Map.get(grouped_alerts, route, []) end)
      |> Enum.uniq()

    gl_alert_count = length(green_line_alerts)

    if Enum.empty?(green_line_alerts) do
      serialize_alert_rows_for_route_fn.("Green")
    else
      gl_stop_sets = Enum.map(Subway.gl_stop_sequences(), &MapSet.new/1)

      {trunk_alerts, branch_alerts} =
        Enum.split_with(
          green_line_alerts,
          &alert_affects_gl_trunk_or_whole_line?(&1, gl_stop_sets)
        )

      case {trunk_alerts, branch_alerts} do
        {[], branch_alerts} ->
          serialize_green_line_branch_alerts_only(branch_alerts)

        {[trunk_alert], []} ->
          %{type: :contracted, alerts: [serialize_trunk_alert(trunk_alert)]}

        {[trunk_alert], branch_alerts} ->
          %{
            type: :contracted,
            alerts: [
              serialize_trunk_alert(trunk_alert),
              serialize_green_line_branch_alert_summary(branch_alerts)
            ]
          }

        {[trunk_alert1, trunk_alert2], []} ->
          %{
            type: :contracted,
            alerts: [
              serialize_trunk_alert(trunk_alert1),
              serialize_trunk_alert(trunk_alert2)
            ]
          }

        _ ->
          %{
            type: :contracted,
            alerts: [
              Serialize.serialize_alert_summary(
                gl_alert_count,
                RoutePill.serialize_route_pill("Green")
              )
            ]
          }
      end
    end
  end

  defp serialize_green_line_branch_alerts_only(branch_alerts) do
    case branch_alerts do
      [alert] ->
        route_ids =
          alert |> Utils.alert_routes() |> Enum.filter(&String.starts_with?(&1, "Green"))

        %{
          type: :contracted,
          alerts: [
            Map.merge(
              %{route_pill: RoutePill.serialize_gl_pill_with_branches(route_ids)},
              serialize_green_line_branch_alert(alert, route_ids)
            )
          ]
        }

      [alert1, alert2] ->
        %{
          type: :contracted,
          alerts: [
            serialize_green_line_branch_alert(alert1, Utils.alert_routes(alert1)),
            serialize_green_line_branch_alert(alert2, Utils.alert_routes(alert2))
          ]
        }

      _ ->
        route_ids =
          branch_alerts
          |> Enum.flat_map(&Utils.alert_routes/1)
          |> Enum.filter(&String.starts_with?(&1, "Green"))

        %{
          type: :contracted,
          alerts: [
            Serialize.serialize_alert_summary(
              length(branch_alerts),
              RoutePill.serialize_gl_pill_with_branches(route_ids)
            )
          ]
        }
    end
  end

  @spec serialize_green_line_branch_alert(SubwayStatus.SubwayStatusAlert.t(), list(String.t())) ::
          SubwayStatus.alert()
  def serialize_green_line_branch_alert(alert, route_ids)

  # If only one branch is affected, we can still determine a stop
  # range to show, for applicable alert types
  def serialize_green_line_branch_alert(alert, [route_id]) do
    Map.merge(
      %{route_pill: RoutePill.serialize_gl_pill_with_branches([route_id])},
      Serialize.serialize_alert(alert, route_id)
    )
  end

  def serialize_green_line_branch_alert(
        %{
          alert: %Alert{
            effect: :station_closure,
            informed_entities: informed_entities
          }
        },
        route_ids
      ) do
    stop_names =
      Enum.flat_map(route_ids, &Utils.get_stop_names_from_ies(informed_entities, &1))

    {status, location} = Utils.format_station_closure(stop_names)

    %{
      route_pill: RoutePill.serialize_gl_pill_with_branches(route_ids),
      status: status,
      location: location,
      station_count: length(stop_names)
    }
  end

  # Otherwise, give up on determining a stop range.
  def serialize_green_line_branch_alert(alert, route_ids) do
    Map.merge(
      %{route_pill: RoutePill.serialize_gl_pill_with_branches(route_ids)},
      Serialize.serialize_alert(alert, "Green")
    )
  end

  defp serialize_green_line_branch_alert_summary(branch_alerts) do
    route_ids =
      branch_alerts
      |> Enum.flat_map(&Utils.alert_routes/1)
      |> Enum.filter(&String.starts_with?(&1, "Green"))

    alert_count = length(branch_alerts)

    case branch_alerts do
      [branch_alert] ->
        serialize_green_line_branch_alert(branch_alert, route_ids)

      _ ->
        Serialize.serialize_alert_summary(
          alert_count,
          RoutePill.serialize_gl_pill_with_branches(route_ids)
        )
    end
  end

  defp serialize_trunk_alert(alert) do
    Map.merge(
      %{route_pill: RoutePill.serialize_route_pill("Green")},
      Serialize.serialize_alert(alert, "Green")
    )
  end

  defp alert_affects_whole_green_line?(%Alert{informed_entities: informed_entities}) do
    alert_whole_line_stops =
      informed_entities
      |> Enum.map(fn e -> Map.get(e, :route) end)
      |> Enum.filter(&(&1 in @green_line_branches))
      |> Enum.uniq()
      |> Enum.sort()

    alert_whole_line_stops == @green_line_branches
  end

  # If any closed stop is served by more than one branch, the alert affects the trunk
  defp alert_affects_gl_trunk?(
         %Alert{
           effect: :station_closure,
           informed_entities: informed_entities
         },
         gl_stop_sets
       ) do
    informed_entities
    |> Enum.map(fn e -> Map.get(e, :stop) end)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.any?(fn informed_stop ->
      Enum.count(gl_stop_sets, &(informed_stop in &1)) > 1
    end)
  end

  # If the affected stops are fully contained in more than one branch, the alert affects the trunk
  defp alert_affects_gl_trunk?(%Alert{informed_entities: informed_entities}, gl_stop_sets) do
    alert_stops =
      informed_entities
      |> Enum.filter(fn
        %{stop: nil} ->
          false

        ie ->
          InformedEntity.parent_station?(ie) and ie.route in @green_line_branches
      end)
      |> Enum.map(& &1.stop)
      |> MapSet.new()

    if MapSet.size(alert_stops) > 0 do
      Enum.count(gl_stop_sets, &MapSet.subset?(alert_stops, &1)) > 1
    else
      false
    end
  end

  defp alert_affects_gl_trunk_or_whole_line?(%{alert: alert}, gl_stop_sets) do
    alert_affects_gl_trunk?(alert, gl_stop_sets) or
      alert_affects_whole_green_line?(alert)
  end
end
