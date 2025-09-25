defmodule Screens.V2.WidgetInstance.SubwayStatus do
  @moduledoc """
  A flex-zone widget that displays a brief status of each subway line.
  """

  alias Screens.Alerts.Alert
  alias Screens.Alerts.InformedEntity
  alias Screens.Routes.Route
  alias Screens.Stops.Subway
  alias Screens.V2.WidgetInstance.SubwayStatus
  alias ScreensConfig.Screen

  defmodule SubwayStatusAlert do
    @moduledoc false

    @type t :: %__MODULE__{
            alert: Alert.t(),
            context: context()
          }

    @enforce_keys [:alert]
    defstruct @enforce_keys ++ [context: %{}]

    @type context :: %{
            optional(:all_platforms_at_informed_station) => list(String.t())
          }
  end

  defstruct screen: nil,
            subway_alerts: nil

  @type t :: %__MODULE__{
          screen: Screen.t(),
          subway_alerts: list(SubwayStatusAlert.t())
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
          optional(:station_count) => integer(),
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

  @subway_routes Map.keys(@route_directions)

  @green_line_branches ["Green-B", "Green-C", "Green-D", "Green-E"]

  @mbta_alerts_url "mbta.com/alerts"

  defimpl Screens.V2.WidgetInstance do
    alias ScreensConfig.Audio
    alias ScreensConfig.Screen.BusShelter

    def priority(_instance), do: [2, 1]

    @spec serialize(SubwayStatus.t()) :: SubwayStatus.serialized_response()
    def serialize(%SubwayStatus{subway_alerts: alerts}) do
      grouped_alerts = SubwayStatus.get_relevant_alerts_by_route(alerts)
      multi_alert_routes = SubwayStatus.get_multi_alert_routes(grouped_alerts)
      total_alert_count = SubwayStatus.get_total_alerts(alerts)

      if Enum.any?(multi_alert_routes) do
        SubwayStatus.serialize_routes_multiple_alerts(
          grouped_alerts,
          multi_alert_routes,
          total_alert_count
        )
      else
        SubwayStatus.serialize_routes_zero_or_one_alert(grouped_alerts, total_alert_count)
      end
    end

    def slot_names(_instance), do: [:medium, :large]

    def widget_type(_instance), do: :subway_status

    def valid_candidate?(_instance), do: true

    def audio_serialize(t), do: serialize(t)

    def audio_sort_key(_instance), do: [3]

    def audio_valid_candidate?(%SubwayStatus{
          screen: %Screen{app_params: %BusShelter{audio: %Audio{interval_enabled: true}}}
        }),
        do: false

    def audio_valid_candidate?(_instance), do: true

    def audio_view(_instance), do: ScreensWeb.V2.Audio.SubwayStatusView
  end

  def get_multi_alert_routes(grouped_alerts) do
    initial_acc = %{"Orange" => [], "Red" => [], "Blue" => [], "Green" => []}

    # Treat all GL branch alerts the same.
    grouped_alerts
    |> Enum.reduce(initial_acc, fn
      {"Green" <> _, alerts}, %{"Green" => gl_alerts} = acc ->
        Map.put(acc, "Green", Enum.uniq(gl_alerts ++ alerts))

      {route, alerts}, acc ->
        Map.put(acc, route, alerts)
    end)
    |> Enum.filter(fn {_route, alerts} -> length(alerts) > 1 end)
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

  defp alert_routes(%{alert: %Alert{informed_entities: entities}}) do
    entities
    |> Enum.map(fn e -> Map.get(e, :route) end)
    |> Enum.reject(&is_nil/1)
    |> Enum.filter(&(&1 in @subway_routes))
    |> Enum.uniq()
  end

  def serialize_one_row_for_all_routes(grouped_alerts, total_alert_count) do
    %{
      blue: serialize_single_alert_row_for_route(grouped_alerts, "Blue", total_alert_count),
      orange: serialize_single_alert_row_for_route(grouped_alerts, "Orange", total_alert_count),
      red: serialize_single_alert_row_for_route(grouped_alerts, "Red", total_alert_count),
      green: serialize_green_line(grouped_alerts, total_alert_count)
    }
  end

  # At most 1 alert on any route
  def serialize_routes_zero_or_one_alert(grouped_alerts, total_alert_count) do
    %{
      blue: serialize_single_alert_row_for_route(grouped_alerts, "Blue", total_alert_count),
      orange: serialize_single_alert_row_for_route(grouped_alerts, "Orange", total_alert_count),
      red: serialize_single_alert_row_for_route(grouped_alerts, "Red", total_alert_count),
      green: serialize_green_line(grouped_alerts, total_alert_count)
    }
  end

  # More than 1 alert on any one route
  def serialize_routes_multiple_alerts(grouped_alerts, multi_alert_routes, total_alert_count) do
    multi_alert_route_ids = Enum.map(multi_alert_routes, &elem(&1, 0))

    cond do
      "Green" in multi_alert_route_ids ->
        # Collapse all non-GL routes and display as many GL alerts as possible.
        %{
          blue: serialize_single_alert_row_for_route(grouped_alerts, "Blue", total_alert_count),
          orange:
            serialize_single_alert_row_for_route(grouped_alerts, "Orange", total_alert_count),
          red: serialize_single_alert_row_for_route(grouped_alerts, "Red", total_alert_count),
          green: serialize_green_line(grouped_alerts, total_alert_count)
        }

      length(multi_alert_route_ids) == 1 ->
        # Make sure the one multi-alert route has only two alerts.
        multi_alert_route_id = List.first(multi_alert_route_ids)
        alerts_for_multi_alert_route = Map.get(grouped_alerts, multi_alert_route_id)

        if length(alerts_for_multi_alert_route) == 2 do
          # Show both alerts in two rows
          %{
            blue: serialize_multiple_alert_rows_for_route(grouped_alerts, "Blue"),
            orange: serialize_multiple_alert_rows_for_route(grouped_alerts, "Orange"),
            red: serialize_multiple_alert_rows_for_route(grouped_alerts, "Red"),
            green: serialize_green_line(grouped_alerts, total_alert_count)
          }
        else
          serialize_one_row_for_all_routes(grouped_alerts, total_alert_count)
        end

      # Collapse all routes
      true ->
        serialize_one_row_for_all_routes(grouped_alerts, total_alert_count)
    end
  end

  # Only executed if one non-GL route has exactly 2 alerts
  def serialize_multiple_alert_rows_for_route(grouped_alerts, route_id) do
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
          [serialize_alert_summary(length(alerts), serialize_route_pill(route_id))]
      end

    %{
      type: :contracted,
      alerts: alert_rows
    }
  end

  # Only executed when route displays one status.
  def serialize_single_alert_row_for_route(grouped_alerts, route_id, total_alert_count) do
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

    if total_alert_count in 1..2 and data.status != "Normal Service" do
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

  defp alert_is_whole_route?(informed_entities) do
    Enum.any?(informed_entities, &InformedEntity.whole_route?/1)
  end

  defp alert_is_whole_direction?(informed_entities) do
    Enum.any?(informed_entities, &InformedEntity.whole_direction?/1)
  end

  defp get_direction(informed_entities, route_id) do
    [%{direction_id: direction_id} | _] =
      Enum.filter(informed_entities, &InformedEntity.whole_direction?/1)

    direction =
      @route_directions
      |> Map.get(route_id)
      |> Enum.at(direction_id)

    %{full: direction, abbrev: direction}
  end

  # credo:disable-for-next-line
  # TODO: get_endpoints is a common function; could be consolidated
  defp get_endpoints(informed_entities, route_id) do
    case Subway.stop_sequence_containing_informed_entities(informed_entities, route_id) do
      nil ->
        nil

      stop_sequence ->
        {min_index, max_index} =
          informed_entities
          |> Enum.filter(&Subway.stop_on_route?(&1.stop, stop_sequence))
          |> Enum.map(&Subway.stop_index_for_informed_entity(&1, stop_sequence))
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
            full: "#{min_full_name} ↔ #{max_full_name}",
            abbrev: "#{min_abbreviated_name} ↔ #{max_abbreviated_name}"
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

  @spec serialize_alert(SubwayStatusAlert.t() | nil, Route.id()) :: alert()
  defp serialize_alert(alert, route_id)

  defp serialize_alert(nil, _route_id) do
    %{status: "Normal Service"}
  end

  defp serialize_alert(
         %{alert: %Alert{effect: :shuttle, informed_entities: informed_entities}},
         route_id
       ) do
    %{status: "Shuttle Bus", location: get_location(informed_entities, route_id)}
  end

  defp serialize_alert(
         %{alert: %Alert{effect: :suspension, informed_entities: informed_entities}},
         route_id
       ) do
    status =
      if alert_is_whole_route?(informed_entities), do: "SERVICE SUSPENDED", else: "Suspension"

    %{status: status, location: get_location(informed_entities, route_id)}
  end

  defp serialize_alert(
         %{
           alert: %Alert{effect: :station_closure, informed_entities: informed_entities} = alert,
           context: %{all_platforms_at_informed_station: all_platforms_at_informed_station}
         },
         route_id
       ) do
    if Alert.partial_station_closure?(alert, all_platforms_at_informed_station) do
      platform_ids = Enum.map(all_platforms_at_informed_station, & &1.id)
      informed_platforms = Enum.filter(informed_entities, &(&1.stop in platform_ids))

      %{
        status:
          Cldr.Message.format!("Bypassing {num_informed_platforms, plural,
                                =1 {1 stop}
                                other {# stops}}",
            num_informed_platforms: length(informed_platforms)
          ),
        location: %{full: @mbta_alerts_url, abbrev: @mbta_alerts_url}
      }
    else
      # Get closed station names from informed entities
      stop_names = get_stop_names_from_informed_entities(informed_entities, route_id)

      {status, location} = format_station_closure(stop_names)

      %{status: status, location: location, station_count: length(stop_names)}
    end
  end

  defp serialize_alert(
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
      location: get_location(informed_entities, route_id)
    }
  end

  defp serialize_alert(
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
        alert_is_whole_route?(informed_entities) -> nil
        # N.B. this is somewhat outside the original purpose of the `location` field since it
        # explains the *cause* of the alert instead; what we'd normally display as the location
        # (e.g. "Oak Grove ↔ North Station") is intentionally omitted, to align with how we're
        # presenting single-tracking alerts in other apps. Reconsider the name "location" if we
        # start doing more of this sort of thing.
        cause == :single_tracking -> %{full: "Due to Single Tracking", abbrev: "Single Tracking"}
        true -> get_location(informed_entities, route_id)
      end

    %{
      status: "Delays #{Alert.delay_description(alert)}",
      location: location
    }
  end

  defp serialize_alert(
         %{
           alert: %Alert{
             effect: :service_change,
             informed_entities: informed_entities
           }
         },
         route_id
       ) do
    location = get_location(informed_entities, route_id)
    %{status: "Service Change", location: location}
  end

  @spec serialize_green_line_branch_alert(%{alert: Alert.t(), context: %{}}, list(String.t())) ::
          alert()
  defp serialize_green_line_branch_alert(alert, route_ids)

  defp serialize_green_line_branch_alert(
         %{
           alert: %Alert{
             effect: :station_closure,
             informed_entities: informed_entities
           }
         },
         route_ids
       ) do
    stop_names =
      Enum.flat_map(route_ids, &get_stop_names_from_informed_entities(informed_entities, &1))

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
  defp serialize_green_line_branch_alert(alert, [route_id]) do
    Map.merge(
      %{route_pill: serialize_gl_pill_with_branches([route_id])},
      serialize_alert(alert, route_id)
    )
  end

  # Otherwise, give up on determining a stop range.
  defp serialize_green_line_branch_alert(alert, route_ids) do
    Map.merge(
      %{route_pill: serialize_gl_pill_with_branches(route_ids)},
      serialize_alert(alert, "Green")
    )
  end

  defp alert_affects_whole_green_line?(%Alert{informed_entities: informed_entities}) do
    alert_whole_line_stops =
      informed_entities
      |> Enum.map(fn e -> Map.get(e, :route) end)
      |> Enum.filter(fn
        "Green-" <> _ -> true
        _ -> false
      end)
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
        %{stop: nil} -> false
        ie -> String.starts_with?(ie.stop, "place-") and String.starts_with?(ie.route, "Green-")
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

  def serialize_green_line(grouped_alerts, total_alert_count) do
    green_line_alerts =
      @green_line_branches
      |> Enum.flat_map(fn route -> Map.get(grouped_alerts, route, []) end)
      |> Enum.uniq()

    gl_alert_count = length(green_line_alerts)

    if gl_alert_count == 0 do
      serialize_single_alert_row_for_route(grouped_alerts, "Green", total_alert_count)
    else
      gl_stop_sets = Enum.map(Subway.gl_stop_sequences(), &MapSet.new/1)

      {trunk_alerts, branch_alerts} =
        Enum.split_with(
          green_line_alerts,
          &alert_affects_gl_trunk_or_whole_line?(&1, gl_stop_sets)
        )

      case {trunk_alerts, branch_alerts} do
        # If there are no alerts for the GL trunk, serialize any alerts on the branches
        {[], branch_alerts} ->
          serialize_green_line_branch_alerts(
            branch_alerts,
            false,
            total_alert_count,
            gl_alert_count
          )

        {[trunk_alert], []} when total_alert_count < 3 ->
          %{type: :extended, alert: serialize_trunk_alert(trunk_alert)}

        {[trunk_alert], []} ->
          %{type: :contracted, alerts: [serialize_trunk_alert(trunk_alert)]}

        # If there is a single alert on the GL trunk, show it in its own row.
        # Show branch alert/summary on another row.
        {[trunk_alert], branch_alerts} ->
          %{
            type: :contracted,
            alerts: [
              serialize_trunk_alert(trunk_alert),
              serialize_green_line_branch_alerts(
                branch_alerts,
                true,
                total_alert_count,
                gl_alert_count
              )
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
            alerts: [serialize_alert_summary(gl_alert_count, serialize_route_pill("Green"))]
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
      location: @mbta_alerts_url
    }
  end

  defp serialize_green_line_branch_alerts(branch_alerts, false, total_alert_count, gl_alert_count) do
    route_ids =
      branch_alerts
      |> Enum.flat_map(&alert_routes/1)
      |> Enum.filter(&String.starts_with?(&1, "Green"))

    alert_count = length(branch_alerts)

    case branch_alerts do
      # One branch alert, no trunk alerts
      [alert] ->
        serialized_alert =
          Map.merge(
            %{route_pill: serialize_gl_pill_with_branches(route_ids)},
            serialize_green_line_branch_alert(alert, route_ids)
          )

        if total_alert_count < 3 and gl_alert_count == 1 do
          %{type: :extended, alert: serialized_alert}
        else
          %{type: :contracted, alerts: [serialized_alert]}
        end

      # 2 branch alerts, no trunk alert
      [alert1, alert2] ->
        %{
          type: :contracted,
          alerts: [
            serialize_green_line_branch_alert(alert1, alert_routes(alert1)),
            serialize_green_line_branch_alert(alert2, alert_routes(alert2))
          ]
        }

      # 3+ branch alerts
      _alerts ->
        %{
          type: :contracted,
          alerts: [
            serialize_alert_summary(alert_count, serialize_gl_pill_with_branches(route_ids))
          ]
        }
    end
  end

  defp serialize_green_line_branch_alerts(branch_alerts, true, _, _) do
    route_ids =
      branch_alerts
      |> Enum.flat_map(&alert_routes/1)
      |> Enum.filter(&String.starts_with?(&1, "Green"))

    alert_count = length(branch_alerts)

    case branch_alerts do
      # Show the branch alert in a row under the trunk alert.
      [branch_alert] ->
        Map.merge(
          %{route_pill: serialize_gl_pill_with_branches(alert_routes(branch_alert))},
          serialize_green_line_branch_alert(branch_alert, route_ids)
        )

      # Always consolidate 2+ branch alerts if there is a trunk alert
      _alerts ->
        serialize_alert_summary(alert_count, serialize_gl_pill_with_branches(route_ids))
    end
  end

  defp get_stop_names_from_informed_entities(informed_entities, route_id) do
    informed_entities
    |> Enum.filter(fn
      %{route: "Green-" <> _} when route_id == "Green" -> true
      %{route: route} -> route == route_id
    end)
    |> Enum.flat_map(fn
      %{stop: stop_id, route: route_id} ->
        stop_names = Subway.route_stop_names(route_id)

        case Map.get(stop_names, stop_id) do
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
         %{full: @mbta_alerts_url, abbrev: @mbta_alerts_url}}
    end
  end

  # If there is a single alert affecting multiple routes, we need to count that as multiple alerts.
  # To get around that case, we can return either the total routes or total alerts, whichever is greater.
  # This will allow us to better determine if :extended or :contracted is needed.
  def get_total_alerts(alerts) do
    total_affected_routes =
      alerts
      |> Enum.map(& &1.alert)
      |> Enum.uniq_by(& &1.id)
      |> Enum.map(&get_total_affected_routes_for_alert/1)
      |> Enum.sum()

    total_alerts =
      alerts
      |> Enum.uniq_by(fn
        "Green-" <> _ -> "Green"
        route_id -> route_id
      end)
      |> length()

    max(total_affected_routes, total_alerts)
  end

  defp get_total_affected_routes_for_alert(%Alert{informed_entities: informed_entities}) do
    # Get all unique routes in informed_entities
    affected_routes =
      informed_entities
      |> Enum.map(fn %{route: route} -> route end)
      |> Enum.filter(fn e ->
        Enum.member?(["Red", "Orange", "Green", "Blue"] ++ @green_line_branches, e)
      end)
      |> Enum.uniq()

    # If an alert affects 1+ GL branches, count it as one route.
    affected_routes =
      affected_routes
      |> Enum.reject(fn route -> String.starts_with?(route, "Green") end)
      |> Enum.concat(["Green"])

    length(affected_routes)
  end
end
