defmodule Screens.V2.WidgetInstance.SubwayStatus.Serialize do
  @moduledoc """
  Main serialization logic for the Subway Status widget.
  """

  alias Screens.Alerts.Alert
  alias Screens.Routes.Route
  alias Screens.V2.WidgetInstance.SubwayStatus
  alias Screens.V2.WidgetInstance.SubwayStatus.Serialize.GreenLine
  alias Screens.V2.WidgetInstance.SubwayStatus.Serialize.RedLine
  alias Screens.V2.WidgetInstance.SubwayStatus.Serialize.RoutePill
  alias Screens.V2.WidgetInstance.SubwayStatus.Serialize.Utils

  @mbta_alerts_url "mbta.com/alerts"
  @normal_service_status "Normal Service"

  # Type aliases for shorter references
  @type alert :: SubwayStatus.alert()
  @type alerts_by_route :: SubwayStatus.alerts_by_route()
  @type contracted_section :: SubwayStatus.contracted_section()
  @type route_pill :: SubwayStatus.route_pill()
  @type section :: SubwayStatus.section()
  @type serialized_response :: SubwayStatus.serialized_response()


  @spec serialize_alerts_into_possible_rows(alerts_by_route()) :: serialized_response()
  def serialize_alerts_into_possible_rows(grouped_alerts) do
    # Returns the max number of possible rows that could be displayed for a given section
    # Up to two rows if there are two or more alerts, otherwise one row,
    serialize_alert_rows_for_route_fn = fn route_id ->
      serialize_alert_rows_for_route(grouped_alerts, route_id)
    end

    %{
      blue: serialize_alert_rows_for_route(grouped_alerts, "Blue"),
      orange: serialize_alert_rows_for_route(grouped_alerts, "Orange"),
      red: RedLine.serialize_rl_alerts(grouped_alerts, serialize_alert_rows_for_route_fn),
      green: GreenLine.serialize_gl_alerts(grouped_alerts, serialize_alert_rows_for_route_fn)
    }
  end

  @spec consolidate_alert_sections(serialized_response()) :: serialized_response()
  def consolidate_alert_sections(sections) do
    # Subway Status section supports a maximum of 5 status rows
    total_rows = count_total_rows(sections)

    if total_rows > 5 do
      consolidate_sections(sections)
    else
      sections
    end
  end

  @spec count_total_rows(serialized_response()) :: non_neg_integer()
  defp count_total_rows(sections) do
    Enum.reduce(sections, 0, fn {_color, %{alerts: alerts}}, acc ->
      acc + length(alerts)
    end)
  end

  @spec consolidate_sections(serialized_response()) :: serialized_response()
  defp consolidate_sections(sections) do
    # Prioritizes showing 2 GL alerts by shortening any other sections with 2+ alerts
    sections
    |> Enum.map(fn {color, section} ->
      case {color, section} do
        {:green, _section} ->
          {color, section}

        {_color, %{type: :contracted, alerts: alerts}} when length(alerts) == 2 ->
          # Consolidate 2-row sections to a single summary row
          {color, consolidate_two_row_section(section, color)}

        {_color, section} ->
          # Keep any other section with a single row as is
          {color, section}
      end
    end)
    |> Enum.into(%{})
  end

  @spec consolidate_two_row_section(contracted_section(), atom()) :: contracted_section()
  defp consolidate_two_row_section(section, color) do
    %{type: :contracted, alerts: alerts} = section
    route_id = color_to_route_id(color)

    # Determine the route pill - check if any alert has branches
    route_pill = get_route_pill_for_consolidated_row(alerts, route_id)

    %{
      type: :contracted,
      alerts: [
        serialize_alert_summary(length(alerts), route_pill)
      ]
    }
  end

  @spec color_to_route_id(atom()) :: String.t()
  defp color_to_route_id(:blue), do: "Blue"
  defp color_to_route_id(:orange), do: "Orange"
  defp color_to_route_id(:red), do: "Red"
  defp color_to_route_id(:green), do: "Green"

  @spec get_route_pill_for_consolidated_row([alert()], String.t()) :: route_pill()
  defp get_route_pill_for_consolidated_row(alerts, route_id) do
    # Check if any alert has a route pill with branches
    # Since we never consolidate GL section, only need to check RL branch
    has_mattapan_branch =
      Enum.any?(alerts, fn alert ->
        case Map.get(alert, :route_pill) do
          %{branches: branches} when is_list(branches) ->
            :m in branches

          _ ->
            false
        end
      end)

    if has_mattapan_branch and route_id == "Red" do
      RoutePill.serialize_rl_mattapan_pill()
    else
      RoutePill.serialize_route_pill(route_id)
    end
  end

  @spec extend_sections_if_needed(serialized_response()) :: serialized_response()
  def extend_sections_if_needed(sections) do
    rows_displaying_alerts = filter_out_rows_with_normal_status(sections)

    if length(rows_displaying_alerts) <= 2 do
      extend_sections_with_alerts(sections, rows_displaying_alerts)
    else
      sections
    end
  end

  @spec filter_out_rows_with_normal_status(serialized_response()) :: [alert()]
  defp filter_out_rows_with_normal_status(sections) do
    sections
    |> Enum.to_list()
    |> Enum.flat_map(fn {_color, %{alerts: alerts}} ->
      Enum.reject(alerts, fn alert ->
        Map.get(alert, :status) == @normal_service_status
      end)
    end)
  end

  @spec extend_sections_with_alerts(serialized_response(), [alert()]) :: serialized_response()
  defp extend_sections_with_alerts(sections, rows_displaying_alerts) do
    sections
    |> Enum.map(fn {color, section} ->
      case section do
        %{type: :contracted, alerts: alerts} ->
          # Check if this section contains any of the non-normal alerts
          contains_alert_status =
            Enum.any?(alerts, fn alert -> alert in rows_displaying_alerts end)

          case {contains_alert_status, alerts} do
            {true, [alert]} ->
              if alert_summary?(alert) do
                {color, section}
              else
                {color, %{type: :extended, alert: alert}}
              end

            _ ->
              {color, section}
          end

        %{type: :extended, alert: _alert} ->
          # Already extended
          {color, section}
      end
    end)
    |> Enum.into(%{})
  end

  @spec alert_summary?(alert()) :: boolean()
  defp alert_summary?(alert) do
    String.ends_with?(Map.get(alert, :status), " current alerts")
  end

  @spec serialize_alert_rows_for_route(alerts_by_route(), String.t()) :: contracted_section()
  def serialize_alert_rows_for_route(grouped_alerts, route_id) do
    alerts = Map.get(grouped_alerts, route_id)

    alert_rows =
      case alerts do
        alerts when is_nil(alerts) or alerts == [] ->
          [serialize_alert_with_route_pill(nil, route_id)]

        [alert] ->
          [serialize_alert_with_route_pill(alert, route_id)]

        [alert1, alert2] ->
          [serialize_alert_with_route_pill(alert1, route_id), serialize_alert(alert2, route_id)]

        alerts ->
          [serialize_alert_summary(length(alerts), RoutePill.serialize_route_pill(route_id))]
      end

    %{
      type: :contracted,
      alerts: alert_rows
    }
  end

  @spec serialize_alert_with_route_pill(SubwayStatus.SubwayStatusAlert.t() | nil,  Route.id()) :: alert()
  def serialize_alert_with_route_pill(alert, route_id) do
    Map.merge(
      %{route_pill: RoutePill.serialize_route_pill(route_id)},
      serialize_alert(alert, route_id)
    )
  end

  @spec serialize_alert(SubwayStatus.SubwayStatusAlert.t() | nil, Route.id()) :: alert()
  def serialize_alert(alert, route_id)

  def serialize_alert(nil, _route_id) do
    %{status: @normal_service_status}
  end

  def serialize_alert(
        %{alert: %Alert{effect: :shuttle, informed_entities: informed_entities}},
        route_id
      ) do
    %{status: "Shuttle Bus", location: Utils.get_location(informed_entities, route_id)}
  end

  def serialize_alert(
        %{alert: %Alert{effect: :suspension, informed_entities: informed_entities}},
        route_id
      ) do
    status =
      if Utils.alert_is_whole_route?(informed_entities),
        do: "SERVICE SUSPENDED",
        else: "Suspension"

    %{status: status, location: Utils.get_location(informed_entities, route_id)}
  end

  def serialize_alert(
        %{
          alert: %Alert{effect: :station_closure, informed_entities: informed_entities} = alert,
          context: %{all_platforms_at_informed_stations: all_platforms_at_informed_stations}
        },
        route_id
      ) do
    case Alert.station_closure_type(alert, all_platforms_at_informed_stations) do
      # Logic for partial_station_closure will remove any alerts that apply to more than
      # a single parent platform.
      :partial_closure ->
        informed_stop_ids = Enum.map(informed_entities, & &1.stop)

        platform_names =
          all_platforms_at_informed_stations
          |> Enum.filter(&(&1.id in informed_stop_ids))
          |> Enum.map(& &1.platform_name)

        %{
          status: "Stop Skipped",
          location:
            Utils.get_stop_name_with_platform(
              informed_entities,
              platform_names,
              route_id
            )
        }

      # If there are multiple stations closed without all of their platforms closed,
      # display the fallback url. This case should not happen frequently, so
      # we default to not providing incorrect information and direct users to the website.
      :partial_closure_multiple_stops ->
        # There could be informed entities for each of the GL branches at the same
        # station, if there is an alert affecting platforms for each line.
        # So we must filter to unique parent_station IDs
        num_parent_stations =
          alert |> Alert.informed_parent_stations() |> Enum.uniq_by(& &1.stop) |> Enum.count()

        %{
          status:
            Cldr.Message.format!(
              "{num_parent_stations, plural, =1 {Stop} other {# Stops}} Skipped",
              num_parent_stations: num_parent_stations
            ),
          location: %{full: @mbta_alerts_url, abbrev: @mbta_alerts_url},
          station_count: num_parent_stations
        }

      :full_station_closure ->
        # Get closed station names from informed entities
        stop_names = Utils.get_stop_names_from_ies(informed_entities, route_id)

        {status, location} = Utils.format_station_closure(stop_names)

        %{status: status, location: location, station_count: length(stop_names)}
    end
  end

  def serialize_alert(
        %{
          alert: %Alert{
            effect: :delay,
            cause: :single_tracking,
            severity: 1,
            informed_entities: informed_entities
          }
        },
        route_id
      ) do
    %{
      # Would normally be the effect (delays), but in this case the alert is informational i.e.
      # has no expected impact on trip times.
      status: "Single Tracking",
      location: Utils.get_location(informed_entities, route_id)
    }
  end

  def serialize_alert(
        %{
          alert:
            %Alert{
              effect: :delay,
              cause: cause,
              informed_entities: informed_entities
            } = alert
        },
        route_id
      ) do
    location =
      cond do
        # It's expected that delays apply to the "entire line" unless otherwise specified, so we
        # can omit that.
        Utils.alert_is_whole_route?(informed_entities) ->
          nil

        # N.B. this is somewhat outside the original purpose of the `location` field since it
        # explains the *cause* of the alert instead; what we'd normally display as the location
        # (e.g. "Oak Grove ↔ North Station") is intentionally omitted, to align with how we're
        # presenting single-tracking alerts in other apps. Reconsider the name "location" if we
        # start doing more of this sort of thing.
        cause == :single_tracking ->
          %{full: "Due to Single Tracking", abbrev: "Single Tracking"}

        true ->
          Utils.get_location(informed_entities, route_id)
      end

    %{
      status: "Delays #{Alert.delay_description(alert)}",
      location: location
    }
  end

  def serialize_alert(
        %{
          alert: %Alert{
            effect: :service_change,
            informed_entities: informed_entities
          }
        },
        route_id
      ) do
    location = Utils.get_location(informed_entities, route_id)
    %{status: "Service Change", location: location}
  end

  @spec serialize_alert_summary(non_neg_integer(), route_pill()) :: alert()
  def serialize_alert_summary(alert_count, route_pill) do
    %{
      route_pill: route_pill,
      status: "#{alert_count} current alerts",
      location: @mbta_alerts_url
    }
  end
end
