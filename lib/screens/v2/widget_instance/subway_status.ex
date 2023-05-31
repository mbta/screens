defmodule Screens.V2.WidgetInstance.SubwayStatus do
  @moduledoc false

  alias Screens.Alerts.Alert
  alias Screens.Config.Screen
  alias Screens.Config.V2.PreFare
  alias Screens.Stops.Stop
  alias Screens.V2.WidgetInstance.SubwayStatus

  defstruct screen: nil,
            subway_alerts: nil

  @type t :: %__MODULE__{
          screen: Screen.t(),
          subway_alerts: list(Alert.t())
        }

  @type serialized_response :: %{
          blue: section(),
          orange: section(),
          red: section(),
          green: section()
        }

  @type section :: extended_section() | contracted_section()

  @type extended_section :: %{
          type: :extended,
          alert: alert()
        }

  @type contracted_section :: %{type: :contracted, alerts: list(alert())}

  @type alert :: %{
          optional(:route_pill) => route_pill(),
          status: String.t(),
          location: String.t() | location_map() | nil
        }

  @type location_map :: %{full: String.t(), abbrev: String.t()}

  @type route_pill :: %{
          optional(:branches) => list(branch()),
          type: :text,
          text: String.t(),
          color: route_color()
        }

  @type branch :: :b | :c | :d | :e

  @type route_color :: :red | :orange | :green | :blue

  @route_directions %{
    "Blue" => ["Westbound", "Eastbound"],
    "Orange" => ["Southbound", "Northbound"],
    "Red" => ["Southbound", "Northbound"],
    "Green-B" => ["Westbound", "Eastbound"],
    "Green-C" => ["Westbound", "Eastbound"],
    "Green-D" => ["Westbound", "Eastbound"],
    "Green-E" => ["Westbound", "Eastbound"],
    "Green" => ["Westbound", "Eastbound"]
  }

  @green_line_branches ["Green-B", "Green-C", "Green-D", "Green-E"]

  defimpl Screens.V2.WidgetInstance do
    def priority(_instance), do: [2, 1]

    @spec serialize(SubwayStatus.t()) :: SubwayStatus.serialized_response()
    def serialize(%SubwayStatus{screen: config, subway_alerts: alerts}) do
      grouped_alerts = SubwayStatus.get_relevant_alerts_by_route(alerts)
      multi_alert_routes = SubwayStatus.get_multi_alert_routes(config, grouped_alerts)

      if Enum.any?(multi_alert_routes) do
        SubwayStatus.serialize_routes_multiple_alerts(config, grouped_alerts)
      else
        SubwayStatus.serialize_routes_zero_or_one_alert(config, grouped_alerts)
      end
    end

    def slot_names(_instance), do: [:medium, :large]

    def widget_type(_instance), do: :subway_status

    def valid_candidate?(_instance), do: true

    def audio_serialize(t), do: serialize(t)

    def audio_sort_key(_instance), do: [1]

    def audio_valid_candidate?(%{screen: %Screen{app_params: %PreFare{}}}), do: true
    def audio_valid_candidate?(_instance), do: false

    def audio_view(_instance), do: ScreensWeb.V2.Audio.SubwayStatusView
  end

  def get_multi_alert_routes(%Screen{app_id: app_id}, grouped_alerts)
      when app_id in [:bus_eink_v2, :gl_eink_v2] do
    Enum.filter(grouped_alerts, fn {_route, alerts} -> length(alerts) > 2 end)
  end

  def get_multi_alert_routes(_, grouped_alerts) do
    Enum.filter(grouped_alerts, fn {_route, alerts} -> length(alerts) > 1 end)
  end

  def get_relevant_alerts_by_route(alerts) do
    alerts
    |> Stream.flat_map(fn alert ->
      alert
      |> alert_routes()
      |> Enum.uniq()
      |> Enum.map(fn route -> {alert, route} end)
    end)
    |> Enum.group_by(
      fn {_alert, route} -> route end,
      fn {alert, _route} -> alert end
    )
  end

  defp alert_routes(%Alert{informed_entities: entities}) do
    entities
    |> Enum.map(fn e -> Map.get(e, :route) end)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  def serialize_one_row_for_all_routes(config, grouped_alerts) do
    %{
      blue: serialize_single_alert_row_for_route(config, grouped_alerts, "Blue"),
      orange: serialize_single_alert_row_for_route(config, grouped_alerts, "Orange"),
      red: serialize_single_alert_row_for_route(config, grouped_alerts, "Red"),
      green: serialize_green_line(config, grouped_alerts)
    }
  end

  # At most 1 alert (lcd) or 2 alerts (e-ink) on any route
  def serialize_routes_zero_or_one_alert(config, grouped_alerts) do
    %{
      blue: serialize_single_alert_row_for_route(config, grouped_alerts, "Blue"),
      orange: serialize_single_alert_row_for_route(config, grouped_alerts, "Orange"),
      red: serialize_single_alert_row_for_route(config, grouped_alerts, "Red"),
      green: serialize_green_line(config, grouped_alerts)
    }
  end

  # More than 1 alert (lcd) or 2 alerts (e-ink) on any one route
  def serialize_routes_multiple_alerts(config, grouped_alerts) do
    routes_with_alerts = Map.keys(grouped_alerts)

    cond do
      Enum.any?(routes_with_alerts, &String.starts_with?(&1, "Green")) ->
        # Collapse all non-GL routes and display as many GL alerts as possible.
        %{
          blue: serialize_single_alert_row_for_route(config, grouped_alerts, "Blue"),
          orange: serialize_single_alert_row_for_route(config, grouped_alerts, "Orange"),
          red: serialize_single_alert_row_for_route(config, grouped_alerts, "Red"),
          green: serialize_green_line(config, grouped_alerts)
        }

      length(routes_with_alerts) == 1 and get_total_alerts(grouped_alerts) == 2 ->
        # Show both alerts in two rows
        %{
          blue: serialize_multiple_alert_rows_for_route(grouped_alerts, "Blue"),
          orange: serialize_multiple_alert_rows_for_route(grouped_alerts, "Orange"),
          red: serialize_multiple_alert_rows_for_route(grouped_alerts, "Red"),
          green: serialize_multiple_alert_rows_for_route(grouped_alerts, "Green")
        }

      # Collapse all routes
      true ->
        serialize_one_row_for_all_routes(config, grouped_alerts)
    end
  end

  # Only executed if one non-GL route has exactly 2 alerts
  def serialize_multiple_alert_rows_for_route(grouped_alerts, route_id) do
    alerts = Map.get(grouped_alerts, route_id)

    alert_rows =
      if is_nil(alerts) or alerts == [] do
        [serialize_alert_with_route_pill(nil, route_id)]
      else
        [alert1, alert2] = alerts

        [
          Map.merge(
            %{route_pill: serialize_route_pill(route_id)},
            serialize_alert(alert1, route_id)
          ),
          serialize_alert(alert2, route_id)
        ]
      end

    %{
      type: :contracted,
      alerts: alert_rows
    }
  end

  # Only executed when route displays one status.
  def serialize_single_alert_row_for_route(%Screen{app_id: app_id}, grouped_alerts, route_id)
      when app_id in [:bus_eink_v2, :gl_eink_v2] do
    alerts = Map.get(grouped_alerts, route_id)

    data =
      case alerts do
        alerts when is_nil(alerts) or alerts == [] ->
          [serialize_alert_with_route_pill(nil, route_id)]

        [alert] ->
          [serialize_alert_with_route_pill(alert, route_id)]

        [alert1, alert2] ->
          [
            serialize_alert_with_route_pill(alert1, route_id),
            serialize_alert_with_route_pill(alert2, route_id)
          ]

        alerts ->
          [serialize_alert_summary(length(alerts), serialize_route_pill(route_id))]
      end

    %{
      type: :contracted,
      alerts: data
    }
  end

  def serialize_single_alert_row_for_route(_, grouped_alerts, route_id) do
    alerts = Map.get(grouped_alerts, route_id)

    data =
      case alerts do
        alerts when is_nil(alerts) or alerts == [] ->
          serialize_alert_with_route_pill(nil, route_id)

        [alert] ->
          serialize_alert_with_route_pill(alert, route_id)

        alerts ->
          serialize_alert_summary(length(alerts), serialize_route_pill(route_id))
      end

    if get_total_alerts(grouped_alerts) in 1..2 and data.status != "Normal Service" do
      %{
        type: :extended,
        alert: data
      }
    else
      %{
        type: :contracted,
        alerts: [data]
      }
    end
  end

  defp serialize_route_pill(route_id) do
    case route_id do
      "Blue" -> %{type: :text, color: :blue, text: "BL"}
      "Orange" -> %{type: :text, color: :orange, text: "OL"}
      "Red" -> %{type: :text, color: :red, text: "RL"}
      _ -> %{type: :text, color: :green, text: "GL"}
    end
  end

  defp serialize_gl_pill_with_branches(route_ids) do
    branches =
      route_ids
      |> Enum.filter(&String.contains?(&1, "Green-"))
      |> Enum.map(fn "Green-" <> branch ->
        branch |> String.downcase() |> String.to_existing_atom()
      end)

    %{type: :text, color: :green, text: "GL", branches: branches}
  end

  defp ie_is_whole_route?(%{route: route_id, direction_id: nil, stop: nil})
       when not is_nil(route_id),
       do: true

  defp ie_is_whole_route?(_), do: false

  defp ie_is_whole_direction?(%{route: route_id, direction_id: direction_id, stop: nil})
       when not is_nil(route_id) and not is_nil(direction_id),
       do: true

  defp ie_is_whole_direction?(_), do: false

  defp alert_is_whole_route?(informed_entities) do
    Enum.any?(informed_entities, &ie_is_whole_route?/1)
  end

  defp alert_is_whole_direction?(informed_entities) do
    Enum.any?(informed_entities, &ie_is_whole_direction?/1)
  end

  defp get_direction(informed_entities, route_id) do
    [%{direction_id: direction_id} | _] =
      Enum.filter(informed_entities, &ie_is_whole_direction?/1)

    direction =
      @route_directions
      |> Map.get(route_id)
      |> Enum.at(direction_id)

    %{full: direction, abbrev: direction}
  end

  # credo:disable-for-next-line
  # TODO: get_endpoints is a common function; could be consolidated
  defp get_endpoints(informed_entities, route_id) do
    case Stop.get_stop_sequence(informed_entities, route_id) do
      nil ->
        nil

      stop_sequence ->
        {min_index, max_index} =
          informed_entities
          |> Enum.filter(&Stop.stop_on_route?(&1.stop, stop_sequence))
          |> Enum.map(&Stop.to_stop_index(&1, stop_sequence))
          |> Enum.min_max()

        {_, {min_full_name, min_abbreviated_name}} = Enum.at(stop_sequence, min_index)
        {_, {max_full_name, max_abbreviated_name}} = Enum.at(stop_sequence, max_index)

        if min_full_name == max_full_name and min_abbreviated_name == max_abbreviated_name do
          %{
            full: "#{min_full_name}",
            abbrev: "#{min_abbreviated_name}"
          }
        else
          %{
            full: "#{min_full_name} to #{max_full_name}",
            abbrev: "#{min_abbreviated_name} to #{max_abbreviated_name}"
          }
        end
    end
  end

  defp get_location(informed_entities, route_id) do
    cond do
      alert_is_whole_route?(informed_entities) ->
        "Entire line"

      alert_is_whole_direction?(informed_entities) ->
        get_direction(informed_entities, route_id)

      true ->
        get_endpoints(informed_entities, route_id)
    end
  end

  defp serialize_alert_with_route_pill(alert, route_id) do
    Map.merge(%{route_pill: serialize_route_pill(route_id)}, serialize_alert(alert, route_id))
  end

  defp serialize_alert(nil, _route_id) do
    %{status: "Normal Service"}
  end

  defp serialize_alert(%Alert{effect: :shuttle, informed_entities: informed_entities}, route_id) do
    %{status: "Shuttle Bus", location: get_location(informed_entities, route_id)}
  end

  defp serialize_alert(
         %Alert{effect: :suspension, informed_entities: informed_entities},
         route_id
       ) do
    location = get_location(informed_entities, route_id)

    status = if location == "Entire line", do: "SERVICE SUSPENDED", else: "Suspension"

    %{status: status, location: location}
  end

  defp serialize_alert(
         %Alert{effect: :station_closure, informed_entities: informed_entities},
         route_id
       ) do
    # Get closed station names from informed entities
    stop_id_to_name = Stop.stop_id_to_name(route_id)
    stop_names = get_stop_names_from_informed_entities(informed_entities, stop_id_to_name)
    {status, location} = format_station_closure(stop_names)

    %{status: status, location: location, station_count: length(stop_names)}
  end

  defp serialize_alert(
         %Alert{
           effect: :delay,
           severity: severity,
           informed_entities: informed_entities
         },
         route_id
       ) do
    {delay_description, delay_minutes} = Alert.interpret_severity(severity)

    duration_text =
      case delay_description do
        :up_to -> "up to #{delay_minutes} minutes"
        :more_than -> "over #{delay_minutes} minutes"
      end

    location =
      case get_location(informed_entities, route_id) do
        # Most delays apply to the whole line. It's not necessary to specify it.
        "Entire line" -> nil
        other -> other
      end

    %{
      status: "Delays #{duration_text}",
      location: location
    }
  end

  def serialize_green_line_branch_alert(
        %Alert{
          effect: :station_closure,
          informed_entities: informed_entities
        },
        route_ids
      ) do
    stop_id_to_name = route_ids |> Enum.flat_map(&Stop.stop_id_to_name/1) |> Enum.into(%{})
    stop_names = get_stop_names_from_informed_entities(informed_entities, stop_id_to_name)

    {status, location} = format_station_closure(stop_names)

    %{
      route_pill: serialize_gl_pill_with_branches(route_ids),
      status: status,
      location: location,
      station_count: length(stop_names)
    }
  end

  # If only one branch is affected, we can still determine a stop
  # range to show, for applicable alert types
  def serialize_green_line_branch_alert(alert, [route_id]) do
    Map.merge(
      %{route_pill: serialize_gl_pill_with_branches([route_id])},
      serialize_alert(alert, route_id)
    )
  end

  # Otherwise, give up on determining a stop range.
  def serialize_green_line_branch_alert(alert, route_ids) do
    Map.merge(
      %{route_pill: serialize_gl_pill_with_branches(route_ids)},
      serialize_alert(alert, "Green")
    )
  end

  defp alert_affects_gl_trunk_or_whole_line?(%Alert{informed_entities: informed_entities}) do
    gl_trunk_stops = Stop.gl_trunk_stops()

    alert_trunk_stops =
      informed_entities
      |> Enum.map(fn e -> Map.get(e, :stop) end)
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()
      |> Enum.into(MapSet.new())
      |> MapSet.intersection(gl_trunk_stops)

    alert_whole_line_stops =
      informed_entities
      |> Enum.map(fn e -> Map.get(e, :route) end)
      |> Enum.filter(fn
        "Green-" <> _ -> true
        _ -> false
      end)
      |> Enum.uniq()
      |> Enum.sort()

    MapSet.size(alert_trunk_stops) > 0 or
      alert_whole_line_stops == @green_line_branches
  end

  def serialize_green_line(config, grouped_alerts) do
    green_line_alerts =
      @green_line_branches
      |> Enum.flat_map(fn route -> Map.get(grouped_alerts, route, []) end)
      |> Enum.uniq()

    alert_count = length(green_line_alerts)

    if alert_count == 0 do
      serialize_single_alert_row_for_route(config, grouped_alerts, "Green")
    else
      {trunk_alerts, branch_alerts} =
        Enum.split_with(green_line_alerts, &alert_affects_gl_trunk_or_whole_line?/1)

      case {trunk_alerts, branch_alerts} do
        # If there are no alerts for the GL trunk, serialize any alerts on the branches
        {[], branch_alerts} ->
          %{type: :contracted, alerts: serialize_green_line_branch_alerts(branch_alerts, false)}

        {[trunk_alert], []} ->
          %{type: :extended, alert: serialize_trunk_alert(trunk_alert)}

        # If there is a single alert on the GL trunk, show it in its own row.
        # Show branch alert/summary on another row.
        {[trunk_alert], branch_alerts} ->
          %{
            type: :contracted,
            alerts: [
              serialize_trunk_alert(trunk_alert),
              serialize_green_line_branch_alerts(branch_alerts, true)
            ]
          }

        # If the only 2 GL alerts are on the trunk, show them both.
        {[trunk_alert1, trunk_alert2], []} ->
          %{
            type: :contracted,
            alerts: [serialize_trunk_alert(trunk_alert1), serialize_trunk_alert(trunk_alert2)]
          }

        # 2+ trunk alerts w/ 1+ branch alert or 3+ trunk alerts
        # show alert count summary
        {_, _} ->
          %{
            type: :contracted,
            alerts: [serialize_alert_summary(alert_count, serialize_route_pill("Green"))]
          }
      end
    end
  end

  defp serialize_trunk_alert(alert) do
    Map.merge(
      %{route_pill: serialize_route_pill("Green")},
      serialize_alert(alert, "Green")
    )
  end

  defp serialize_alert_summary(alert_count, route_pill) do
    %{
      route_pill: route_pill,
      status: "#{alert_count} current alerts",
      location: "mbta.com/alerts"
    }
  end

  defp serialize_green_line_branch_alerts(branch_alerts, has_trunk_alert) do
    route_ids = Enum.flat_map(branch_alerts, &alert_routes/1)
    alert_count = length(branch_alerts)

    case {branch_alerts, has_trunk_alert} do
      # Show the branch alert in a row under the trunk alert.
      {[alert], true} ->
        Map.merge(
          %{route_pill: serialize_gl_pill_with_branches(alert_routes(alert))},
          serialize_green_line_branch_alert(alert, alert_routes(alert))
        )

      # Always consolidate 2+ branch alerts if there is a trunk alert
      {_alerts, true} ->
        serialize_alert_summary(alert_count, serialize_gl_pill_with_branches(route_ids))

      # One branch alert, no trunk alerts
      {[alert], false} ->
        route_id = List.first(route_ids, "Green")

        [
          Map.merge(
            %{route_pill: serialize_gl_pill_with_branches(route_ids)},
            serialize_alert(alert, route_id)
          )
        ]

      # 2 branch alerts, no trunk alert
      {[alert1, alert2], false} ->
        [
          serialize_green_line_branch_alert(alert1, alert_routes(alert1)),
          serialize_green_line_branch_alert(alert2, alert_routes(alert2))
        ]

      # 3+ branch alerts
      {_alerts, false} ->
        [
          serialize_alert_summary(alert_count, serialize_gl_pill_with_branches(route_ids))
        ]
    end
  end

  defp get_stop_names_from_informed_entities(informed_entities, stop_id_to_name) do
    informed_entities
    |> Enum.flat_map(fn
      %{stop: stop_id} ->
        case Map.get(stop_id_to_name, stop_id) do
          nil -> []
          name -> [name]
        end

      _ ->
        []
    end)
    |> Enum.uniq()
  end

  defp format_station_closure(stop_names) do
    case stop_names do
      [] ->
        {"Bypassing", nil}

      [stop_name] ->
        {full_name, abbreviated_name} = stop_name
        {"Bypassing", %{full: full_name, abbrev: abbreviated_name}}

      [stop_name1, stop_name2] ->
        {full_name1, abbreviated_name1} = stop_name1
        {full_name2, abbreviated_name2} = stop_name2

        {"Bypassing",
         %{
           full: "#{full_name1} and #{full_name2}",
           abbrev: "#{abbreviated_name1} and #{abbreviated_name2}"
         }}

      [stop_name1, stop_name2, stop_name3] ->
        {full_name1, abbreviated_name1} = stop_name1
        {full_name2, abbreviated_name2} = stop_name2
        {full_name3, abbreviated_name3} = stop_name3

        {"Bypassing",
         %{
           full: "#{full_name1}, #{full_name2} & #{full_name3}",
           abbrev: "#{abbreviated_name1}, #{abbreviated_name2} & #{abbreviated_name3}"
         }}

      stop_names ->
        {"Bypassing #{length(stop_names)} stops",
         %{full: "mbta.com/alerts", abbrev: "mbta.com/alerts"}}
    end
  end

  defp get_total_alerts(grouped_alerts) do
    grouped_alerts
    |> Enum.flat_map(&elem(&1, 1))
    |> Enum.uniq_by(fn
      "Green-" <> _ -> "Green"
      route_id -> route_id
    end)
    |> length()
  end
end
