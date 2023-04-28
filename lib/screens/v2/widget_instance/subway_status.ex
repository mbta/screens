defmodule Screens.V2.WidgetInstance.SubwayStatus do
  @moduledoc false

  require Logger

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
          route_pill: route_pill() | nil,
          status: String.t(),
          location: String.t() | location_map() | nil
        }

  @type location_map :: %{full: String.t(), abbrev: String.t()}

  @type route_pill :: %{
          type: :text,
          text: String.t(),
          color: route_color(),
          branches: list(branch()) | nil
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
    def serialize(%SubwayStatus{subway_alerts: alerts}) do
      grouped_alerts = SubwayStatus.get_relevant_alerts_by_route(alerts)

      multi_alert_routes =
        grouped_alerts
        |> Enum.into([])
        |> Enum.filter(fn {_route, alerts} -> length(alerts) > 1 end)

      if Enum.any?(multi_alert_routes) do
        SubwayStatus.serialize_routes_multiple_alerts(grouped_alerts)
      else
        SubwayStatus.serialize_routes_zero_or_one_alert(grouped_alerts)
      end
    end

    def slot_names(_instance), do: [:large]

    def widget_type(_instance), do: :subway_status

    def valid_candidate?(_instance), do: true

    def audio_serialize(t), do: serialize(t)

    def audio_sort_key(_instance), do: [1]

    def audio_valid_candidate?(%{screen: %Screen{app_params: %PreFare{}}}), do: true
    def audio_valid_candidate?(_instance), do: false

    def audio_view(_instance), do: ScreensWeb.V2.Audio.SubwayStatusView
  end

  def get_relevant_alerts_by_route(alerts) do
    alerts
    |> Stream.flat_map(fn alert ->
      alert
      |> alert_routes()
      |> Enum.map(fn
        "Green-" <> _ -> {alert, "Green"}
        route -> {alert, route}
      end)
      |> Enum.uniq()
    end)
    |> Enum.group_by(
      fn
        {_alert, "Green" <> _} -> "Green"
        {_alert, route} -> route
      end,
      fn {alert, _route} -> alert end
    )
  end

  defp alert_routes(%Alert{informed_entities: entities}) do
    entities
    |> Enum.map(fn e -> Map.get(e, :route) end)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  def serialize_one_row_for_all_routes(grouped_alerts) do
    %{
      blue: serialize_single_alert_row_for_route(grouped_alerts, "Blue", :contracted),
      orange: serialize_single_alert_row_for_route(grouped_alerts, "Orange", :contracted),
      red: serialize_single_alert_row_for_route(grouped_alerts, "Red", :contracted),
      green: serialize_single_alert_row_for_route(grouped_alerts, "Green", :contracted)
    }
  end

  # At most 1 alert on any route
  def serialize_routes_zero_or_one_alert(grouped_alerts) do
    total_alerts = grouped_alerts |> Enum.flat_map(&elem(&1, 1)) |> length()
    row_type = if total_alerts in 1..2, do: :extended, else: :contracted

    %{
      blue: serialize_single_alert_row_for_route(grouped_alerts, "Blue", row_type),
      orange: serialize_single_alert_row_for_route(grouped_alerts, "Orange", row_type),
      red: serialize_single_alert_row_for_route(grouped_alerts, "Red", row_type),
      green: serialize_single_alert_row_for_route(grouped_alerts, "Green", row_type)
    }
  end

  # More than 1 alert on any one route
  def serialize_routes_multiple_alerts(grouped_alerts) do
    routes_with_alerts = Map.keys(grouped_alerts)
    total_alerts = grouped_alerts |> Enum.flat_map(&elem(&1, 1)) |> length()

    if "Green" in routes_with_alerts do
      # Collapse all non-GL routes and display as many GL alerts as possible.
      %{
        blue: serialize_single_alert_row_for_route(grouped_alerts, "Blue", :contracted),
        orange: serialize_single_alert_row_for_route(grouped_alerts, "Orange", :contracted),
        red: serialize_single_alert_row_for_route(grouped_alerts, "Red", :contracted),
        green: serialize_green_line(grouped_alerts)
      }
    else
      if length(routes_with_alerts) == 1 and total_alerts == 2 do
        # Show both alerts in two rows
        %{
          blue: serialize_multiple_alert_rows_for_route(grouped_alerts, "Blue"),
          orange: serialize_multiple_alert_rows_for_route(grouped_alerts, "Orange"),
          red: serialize_multiple_alert_rows_for_route(grouped_alerts, "Red"),
          green: serialize_multiple_alert_rows_for_route(grouped_alerts, "Green")
        }
      else
        # Collapse all routes
        serialize_one_row_for_all_routes(grouped_alerts)
      end
    end
  end

  # Only executed if one non-GL route has exactly 2 alerts
  def serialize_multiple_alert_rows_for_route(grouped_alerts, route_id) do
    alerts = Map.get(grouped_alerts, route_id)

    alert_rows =
      if is_nil(alerts) or alerts == [] do
        [%{status: "Normal Service"}]
      else
        [alert1, alert2] = alerts

        [
          Map.merge(
            %{route_pill: serialize_route_pill(route_id), location: nil},
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
  def serialize_single_alert_row_for_route(grouped_alerts, route_id, type) do
    alerts = Map.get(grouped_alerts, route_id)

    data =
      case alerts do
        alerts when is_nil(alerts) or alerts == [] ->
          %{status: "Normal Service"}

        [alert] ->
          serialize_alert(alert, route_id)

        # move this
        alerts ->
          _ =
            Logger.info(
              "[subway_status_multiple_alerts] route=#{route_id} count=#{length(alerts)}"
            )

          %{
            status: "#{length(alerts)} alerts",
            location: %{full: "mbta.com/alerts/subway", abbrev: "mbta.com/alerts/subway"}
          }
      end

    if type == :extended do
      %{
        type: type,
        alert: Map.merge(%{route_pill: serialize_route_pill(route_id), location: nil}, data)
      }
    else
      %{
        type: type,
        alerts: [Map.merge(%{route_pill: serialize_route_pill(route_id), location: nil}, data)]
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

        {_, min_station_name} = Enum.at(stop_sequence, min_index)
        {_, max_station_name} = Enum.at(stop_sequence, max_index)

        {min_full_name, min_abbreviated_name} = min_station_name
        {max_full_name, max_abbreviated_name} = max_station_name

        %{
          full: "#{min_full_name} to #{max_full_name}",
          abbrev: "#{min_abbreviated_name} to #{max_abbreviated_name}"
        }
    end
  end

  defp get_location(informed_entities, route_id) do
    cond do
      alert_is_whole_route?(informed_entities) ->
        nil

      alert_is_whole_direction?(informed_entities) ->
        get_direction(informed_entities, route_id)

      true ->
        get_endpoints(informed_entities, route_id)
    end
  end

  defp serialize_alert(%Alert{effect: :shuttle, informed_entities: informed_entities}, route_id) do
    %{status: "Shuttles", location: get_location(informed_entities, route_id)}
  end

  defp serialize_alert(
         %Alert{effect: :suspension, informed_entities: informed_entities},
         route_id
       ) do
    location = get_location(informed_entities, route_id)
    status = if is_nil(location), do: "SERVICE SUSPENDED", else: "Suspension"
    %{status: status, location: location}
  end

  defp serialize_alert(
         %Alert{effect: :station_closure, informed_entities: informed_entities},
         route_id
       ) do
    # Get closed station names from informed entities
    stop_id_to_name = Stop.stop_id_to_name(route_id)

    stop_names =
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

    location =
      case stop_names do
        [] ->
          _ = Logger.info("[subway_status_empty_bypassing]")
          nil

        [stop_name] ->
          {full_name, abbreviated_name} = stop_name
          %{full: full_name, abbrev: abbreviated_name}

        [stop_name1, stop_name2] ->
          {full_name1, abbreviated_name1} = stop_name1
          {full_name2, abbreviated_name2} = stop_name2

          %{
            full: "#{full_name1} and #{full_name2}",
            abbrev: "#{abbreviated_name1} and #{abbreviated_name2}"
          }

        stop_names ->
          %{full: "#{length(stop_names)} stops", abbrev: "#{length(stop_names)} stops"}
      end

    %{status: "Bypassing", location: location}
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
        :up_to -> "up to #{delay_minutes}m"
        :more_than -> "over #{delay_minutes}m"
      end

    %{status: "Delays #{duration_text}", location: get_location(informed_entities, route_id)}
  end

  def serialize_green_line_branch_alert(%Alert{effect: :suspension}, route_ids),
    do: %{route_pill: serialize_gl_pill_with_branches(route_ids), status: "Suspension"}

  def serialize_green_line_branch_alert(%Alert{effect: :shuttle}, route_ids),
    do: %{route_pill: serialize_gl_pill_with_branches(route_ids), status: "Shuttles"}

  def serialize_green_line_branch_alert(%Alert{effect: :delay}, route_ids),
    do: %{route_pill: serialize_gl_pill_with_branches(route_ids), status: "Delays"}

  def serialize_green_line_branch_alert(
        %Alert{
          effect: :station_closure,
          informed_entities: informed_entities
        },
        route_ids
      ) do
    stations = get_stations(informed_entities)
    station_count = length(stations)

    _ =
      if station_count == 0 do
        Logger.info("[subway_status_station_count_zero]")
      end

    %{
      route_pill: serialize_gl_pill_with_branches(route_ids),
      status: "Bypassing #{station_count} #{if station_count == 1, do: "stop", else: "stops"}"
    }
  end

  def get_stations(informed_entities) do
    informed_entities
    |> Enum.map(fn %{stop: stop_id} -> stop_id end)
    |> Enum.filter(&String.starts_with?(&1, "place-"))
  end

  def group_green_line_branch_statuses(statuses_by_route) do
    statuses_by_route
    |> Enum.flat_map(fn {route, statuses} -> Enum.map(statuses, fn s -> {route, s} end) end)
    |> Enum.group_by(fn {_route, status} -> status end, fn {route, _status} -> route end)
    |> Enum.map(fn {status, routes} -> [Enum.uniq(routes), status] end)
    |> Enum.sort_by(fn [[first_route | _other_routes], _status] -> first_route end)
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

  defp is_multi_route?(alert) do
    length(alert_routes(alert)) > 1
  end

  def serialize_green_line(grouped_alerts) do
    green_line_alerts = grouped_alerts |> Map.get("Green") |> Enum.uniq()

    alert_count = length(green_line_alerts)

    if alert_count == 1 do
      serialize_single_alert_row_for_route(grouped_alerts, "Green", :contracted)
    else
      multi_route_alerts = Enum.filter(green_line_alerts, &is_multi_route?/1)
      trunk_alerts = Enum.filter(multi_route_alerts, &alert_affects_gl_trunk_or_whole_line?/1)
      branch_alerts = green_line_alerts -- trunk_alerts

      alerts =
        case trunk_alerts do
          [] ->
            # If there are no alerts for the GL trunk, serialize any alerts on the branches
            serialize_green_line_branch_alerts(branch_alerts, false)

          [trunk_alert] ->
            # If there is a single alert on the GL trunk, show it in its own row.
            # Show branch alert(s) in another row.
            [
              Map.merge(
                %{route_pill: serialize_route_pill("Green")},
                serialize_alert(trunk_alert, "Green")
              ),
              serialize_green_line_branch_alerts(branch_alerts, true)
            ]

          _ ->
            # If there are multiple alerts on the GL trunk, log it and serialize the count
            _ =
              Logger.info(
                "[subway_status_multiple_alerts] route=Green-Trunk count=#{alert_count}"
              )

            serialize_single_alert_row_for_route(grouped_alerts, "Green", :contracted)
        end

      %{type: :contracted, alerts: alerts}
    end
  end

  defp serialize_green_line_branch_alerts(branch_alerts, has_trunk_alert) do
    route_ids = Enum.flat_map(branch_alerts, &alert_routes/1)

    case {branch_alerts, has_trunk_alert} do
      {[alert], true} ->
        %{
          route_pill: serialize_gl_pill_with_branches(alert_routes(alert)),
          alerts: [serialize_green_line_branch_alert(alert, alert_routes(alert))]
        }

      {alerts, true} ->
        %{
          route_pill: serialize_gl_pill_with_branches(route_ids),
          status: "#{length(alerts)} alerts",
          location: %{full: "mbta.com/alerts/subway", abbrev: "mbta.com/alerts/subway"}
        }

      # One GL branch alert
      {[alert], false} ->
        Map.merge(
          %{route_pill: serialize_gl_pill_with_branches(route_ids)},
          serialize_green_line_branch_alert(alert, route_ids)
        )

      # One group of GL branch alerts
      {[alert1, alert2], false} ->
        [
          serialize_green_line_branch_alert(alert1, alert_routes(alert1)),
          serialize_green_line_branch_alert(alert2, alert_routes(alert2))
        ]

      {alerts, false} ->
        %{
          route_pill: serialize_gl_pill_with_branches(route_ids),
          status: "#{length(alerts)} alerts",
          location: %{full: "mbta.com/alerts/subway", abbrev: "mbta.com/alerts/subway"}
        }
    end
  end
end
