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
            optional(:all_platforms_at_informed_stations) => list(String.t())
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
    "Green" => ["Westbound", "Eastbound"],
    "Mattapan" => ["Southbound", "Northbound"]
  }

  @subway_routes Map.keys(@route_directions)

  @green_line_branches ["Green-B", "Green-C", "Green-D", "Green-E"]

  @green_line_route_ids ["Green" | @green_line_branches]

  @mbta_alerts_url "mbta.com/alerts"
  @normal_service_status "Normal Service"

  defimpl Screens.V2.WidgetInstance do
    alias ScreensConfig.Audio
    alias ScreensConfig.Screen.BusShelter

    def priority(_instance), do: [2, 1]

    @spec serialize(SubwayStatus.t()) :: SubwayStatus.serialized_response()
    def serialize(%SubwayStatus{subway_alerts: alerts}) do
      # Serializes by following the below process:
      # 1. Fetch potential relevant alerts for each line
      # 2. Serialize with maximum number of rows for each section
      # 3. Consolidate sections if there are too many with 2 alert rows
      # 4. Marks alert rows as extended if there is space
      alerts
      |> SubwayStatus.get_relevant_alerts_by_route()
      |> SubwayStatus.serialize_alerts_into_possible_rows()
      |> SubwayStatus.consolidate_alert_sections()
      |> SubwayStatus.extend_sections_if_needed()
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

  ##########################
  # Fetch relevant alerts  #
  ##########################
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

  ##########################
  # Serialize all alerts   #
  ##########################

  @spec serialize_alerts_into_possible_rows(map()) :: serialized_response()
  def serialize_alerts_into_possible_rows(grouped_alerts) do
    # Returns the max number of possible rows that could be displayed for a given section
    # Up to two rows if there are two or more alerts, otherwise one row,
    %{
      blue: serialize_alert_rows_for_route(grouped_alerts, "Blue"),
      orange: serialize_alert_rows_for_route(grouped_alerts, "Orange"),
      red: serialize_red_line_alerts(grouped_alerts),
      green: serialize_green_line_alerts(grouped_alerts)
    }
  end

  ##########################
  # Consolidate Sections   #
  ##########################

  def consolidate_alert_sections(sections) do
    # Subway Status section supports a maximum of 5 status rows
    total_rows = count_total_rows(sections)

    if total_rows > 5 do
      consolidate_sections(sections)
    else
      sections
    end
  end

  defp count_total_rows(sections) do
    Enum.reduce(sections, 0, fn {_color, %{alerts: alerts}}, acc ->
      acc + length(alerts)
    end)
  end

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

  defp color_to_route_id(:blue), do: "Blue"
  defp color_to_route_id(:orange), do: "Orange"
  defp color_to_route_id(:red), do: "Red"
  defp color_to_route_id(:green), do: "Green"

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
      serialize_rl_mattapan_pill()
    else
      serialize_route_pill(route_id)
    end
  end

  ###################
  # Extend Sections #
  ###################

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
  defp(extend_sections_with_alerts(sections, rows_displaying_alerts)) do
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

  ##############################
  # Shared Serialization Logic #
  ##############################

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
          [serialize_alert_summary(length(alerts), serialize_route_pill(route_id))]
      end

    %{
      type: :contracted,
      alerts: alert_rows
    }
  end

  defp serialize_alert_with_route_pill(alert, route_id) do
    Map.merge(%{route_pill: serialize_route_pill(route_id)}, serialize_alert(alert, route_id))
  end

  @spec serialize_alert(SubwayStatusAlert.t() | nil, Route.id()) :: alert()
  defp serialize_alert(alert, route_id)

  defp serialize_alert(nil, _route_id) do
    %{status: @normal_service_status}
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
            get_stop_name_with_platform(
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

  defp serialize_alert_summary(alert_count, route_pill) do
    %{
      route_pill: route_pill,
      status: "#{alert_count} current alerts",
      location: @mbta_alerts_url
    }
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
        case route_id do
          "Mattapan" -> "Entire Mattapan line"
          _ -> "Entire line"
        end

      alert_is_whole_direction?(informed_entities) ->
        get_direction(informed_entities, route_id)

      true ->
        get_endpoints(informed_entities, route_id)
    end
  end

  #######################
  # Green Line Specific #
  #######################

  defp serialize_green_line_alerts(grouped_alerts) do
    green_line_alerts =
      @green_line_branches
      |> Enum.flat_map(fn route -> Map.get(grouped_alerts, route, []) end)
      |> Enum.uniq()

    gl_alert_count = length(green_line_alerts)

    if Enum.empty?(green_line_alerts) do
      serialize_alert_rows_for_route(grouped_alerts, "Green")
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
            alerts: [serialize_alert_summary(gl_alert_count, serialize_route_pill("Green"))]
          }
      end
    end
  end

  defp serialize_green_line_branch_alerts_only(branch_alerts) do
    case branch_alerts do
      [alert] ->
        route_ids = alert |> alert_routes() |> Enum.filter(&String.starts_with?(&1, "Green"))

        %{
          type: :contracted,
          alerts: [
            Map.merge(
              %{route_pill: serialize_gl_pill_with_branches(route_ids)},
              serialize_green_line_branch_alert(alert, route_ids)
            )
          ]
        }

      [alert1, alert2] ->
        %{
          type: :contracted,
          alerts: [
            serialize_green_line_branch_alert(alert1, alert_routes(alert1)),
            serialize_green_line_branch_alert(alert2, alert_routes(alert2))
          ]
        }

      _ ->
        route_ids =
          branch_alerts
          |> Enum.flat_map(&alert_routes/1)
          |> Enum.filter(&String.starts_with?(&1, "Green"))

        %{
          type: :contracted,
          alerts: [
            serialize_alert_summary(
              length(branch_alerts),
              serialize_gl_pill_with_branches(route_ids)
            )
          ]
        }
    end
  end

  defp serialize_green_line_branch_alert_summary(branch_alerts) do
    route_ids =
      branch_alerts
      |> Enum.flat_map(&alert_routes/1)
      |> Enum.filter(&String.starts_with?(&1, "Green"))

    alert_count = length(branch_alerts)

    case branch_alerts do
      [branch_alert] ->
        serialize_green_line_branch_alert(branch_alert, route_ids)

      _ ->
        serialize_alert_summary(alert_count, serialize_gl_pill_with_branches(route_ids))
    end
  end

  @spec serialize_green_line_branch_alert(%{alert: Alert.t(), context: %{}}, list(String.t())) ::
          alert()
  defp serialize_green_line_branch_alert(alert, route_ids)

  # If only one branch is affected, we can still determine a stop
  # range to show, for applicable alert types
  defp serialize_green_line_branch_alert(alert, [route_id]) do
    Map.merge(
      %{route_pill: serialize_gl_pill_with_branches([route_id])},
      serialize_alert(alert, route_id)
    )
  end

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

  defp serialize_trunk_alert(alert) do
    Map.merge(
      %{route_pill: serialize_route_pill("Green")},
      serialize_alert(alert, "Green")
    )
  end

  #######################
  # Red Line Specific   #
  #######################
  defp serialize_red_line_alerts(grouped_alerts) do
    red_alerts = Map.get(grouped_alerts, "Red", [])
    mattapan_alerts = Map.get(grouped_alerts, "Mattapan", [])

    cond do
      # Serialize a row for RL and for Mattapan branch
      !Enum.empty?(red_alerts) and !Enum.empty?(mattapan_alerts) ->
        serialize_red_and_mattapan(red_alerts, mattapan_alerts)

      !Enum.empty?(mattapan_alerts) ->
        serialize_mattapan_only(grouped_alerts)

      true ->
        serialize_alert_rows_for_route(grouped_alerts, "Red")
    end
  end

  defp serialize_mattapan_only(grouped_alerts) do
    mattapan_alerts = Map.get(grouped_alerts, "Mattapan", [])

    if length(mattapan_alerts) < 3 do
      %{
        type: :contracted,
        alerts: Enum.map(mattapan_alerts, &serialize_red_line_branch_alert/1)
      }
    else
      %{
        type: :contracted,
        alerts: [serialize_alert_summary(length(mattapan_alerts), serialize_rl_mattapan_pill())]
      }
    end
  end

  defp serialize_red_and_mattapan(red_alerts, mattapan_alerts) do
    red_count = length(red_alerts)
    mattapan_count = length(mattapan_alerts)

    serialized_red =
      if red_count == 1 do
        serialize_alert_with_route_pill(List.first(red_alerts), "Red")
      else
        serialize_alert_summary(red_count, serialize_route_pill("Red"))
      end

    serialized_mattapan =
      if mattapan_count == 1 do
        serialize_red_line_branch_alert(List.first(mattapan_alerts))
      else
        serialize_alert_summary(mattapan_count, serialize_rl_mattapan_pill())
      end

    %{
      type: :contracted,
      alerts: [serialized_red, serialized_mattapan]
    }
  end

  defp serialize_red_line_branch_alert(alert) do
    Map.merge(
      %{route_pill: serialize_rl_mattapan_pill()},
      serialize_alert(alert, "Mattapan")
    )
  end

  ############################
  # Route Pill Serialization #
  ############################
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
      |> Enum.filter(&(&1 in @green_line_branches))
      |> Enum.map(fn "Green-" <> branch ->
        branch |> String.downcase() |> String.to_existing_atom()
      end)

    %{type: :text, color: :green, text: "GL", branches: branches}
  end

  defp serialize_rl_mattapan_pill do
    %{type: :text, color: :red, text: "RL", branches: [:m]}
  end

  ####################################
  # Station Closure Helper Functions #
  ####################################

  defp get_stop_name_with_platform(informed_entities, [platform_name], route_id) do
    # Although it is possible to create a closure alert for multiple partial stations,
    # we pass along platform info only if a single platform is closed at that station.
    # Otherwise we will set an informational URL as the location name to display to the user
    stop_names = Subway.route_stop_names(route_id)
    relevant_entities = filter_entities_by_route(informed_entities, route_id)

    parent_station_id =
      Enum.find_value(relevant_entities, fn %{stop: stop_id} ->
        if Map.has_key?(stop_names, stop_id), do: stop_id
      end)

    case Map.get(stop_names, parent_station_id) do
      {full, _abbrev} ->
        %{
          full: "#{full}: #{platform_name} platform closed",
          abbrev: "#{full} (1 side only)"
        }

      nil ->
        %{full: @mbta_alerts_url, abbrev: @mbta_alerts_url}
    end
  end

  defp get_stop_name_with_platform(_informed_entities, _platform_names, _route_id) do
    # If there are multiple platforms or no platforms closed, then use fallback alerts URL
    %{full: @mbta_alerts_url, abbrev: @mbta_alerts_url}
  end

  defp get_stop_names_from_informed_entities(informed_entities, route_id) do
    informed_entities
    |> filter_entities_by_route(route_id)
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
        {"Skipping", nil}

      [stop_name] ->
        {full_name, abbreviated_name} = stop_name
        {"Stop Skipped", %{full: full_name, abbrev: abbreviated_name}}

      [stop_name1, stop_name2] ->
        {full_name1, abbreviated_name1} = stop_name1
        {full_name2, abbreviated_name2} = stop_name2

        {"2 Stops Skipped",
         %{
           full: "#{full_name1} and #{full_name2}",
           abbrev: "#{abbreviated_name1} and #{abbreviated_name2}"
         }}

      [stop_name1, stop_name2, stop_name3] ->
        {full_name1, _abbreviated_name1} = stop_name1
        {full_name2, _abbreviated_name2} = stop_name2
        {full_name3, _abbreviated_name3} = stop_name3

        {"3 Stops Skipped",
         %{
           full: "#{full_name1}, #{full_name2}, and #{full_name3}",
           abbrev: @mbta_alerts_url
         }}

      stop_names ->
        {"#{length(stop_names)} Stops Skipped",
         %{full: @mbta_alerts_url, abbrev: @mbta_alerts_url}}
    end
  end

  defp filter_entities_by_route(informed_entities, route_id) do
    Enum.filter(informed_entities, fn
      %{route: entity_route} -> matches_route?(entity_route, route_id)
      _ -> false
    end)
  end

  defp matches_route?(entity_route, route_id)
       when route_id == "Green" and entity_route in @green_line_route_ids,
       do: true

  defp matches_route?(entity_route, route_id), do: entity_route == route_id
end
