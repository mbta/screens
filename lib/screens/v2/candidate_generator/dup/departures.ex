defmodule Screens.V2.CandidateGenerator.Dup.Departures do
  @moduledoc false

  require Logger

  alias Screens.Alerts.Alert
  alias Screens.Config.Screen
  alias Screens.Config.V2.Departures
  alias Screens.Config.V2.Departures.{Headway, Query, Section}
  alias Screens.Config.V2.Departures.Query.Params
  alias Screens.Config.V2.Dup
  alias Screens.Routes.Route
  alias Screens.SignsUiConfig
  alias Screens.Util
  alias Screens.V2.CandidateGenerator.Widgets
  alias Screens.V2.Departure
  alias Screens.V2.WidgetInstance.Departures, as: DeparturesWidget
  alias Screens.V2.WidgetInstance.{DeparturesNoData, OvernightDepartures}

  def departures_instances(
        %Screen{
          app_params: %Dup{
            primary_departures: %Departures{sections: primary_sections},
            secondary_departures: %Departures{sections: secondary_sections}
          }
        } = config,
        now,
        fetch_section_departures_fn \\ &Widgets.Departures.fetch_section_departures/1,
        fetch_alerts_fn \\ &Alert.fetch_or_empty_list/1,
        fetch_schedules_fn \\ &Screens.Schedules.Schedule.fetch/2,
        create_station_with_routes_map_fn \\ &Screens.Stops.Stop.create_station_with_routes_map/1,
        fetch_vehicles_fn \\ &Screens.Vehicles.Vehicle.by_route_and_direction/2
      ) do
    primary_departures_instances =
      primary_sections
      |> get_sections_data(
        fetch_section_departures_fn,
        fetch_alerts_fn,
        create_station_with_routes_map_fn,
        now
      )
      |> sections_data_to_departure_instances(
        config,
        [
          :main_content_zero,
          :main_content_one,
          :main_content_reduced_zero,
          :main_content_reduced_one
        ],
        now,
        fetch_schedules_fn,
        fetch_vehicles_fn
      )

    secondary_sections =
      if secondary_sections == [] do
        primary_sections
      else
        secondary_sections
      end

    secondary_departures_instances =
      secondary_sections
      |> get_sections_data(
        fetch_section_departures_fn,
        fetch_alerts_fn,
        create_station_with_routes_map_fn,
        now
      )
      |> sections_data_to_departure_instances(
        config,
        [:main_content_two, :main_content_reduced_two],
        now,
        fetch_schedules_fn,
        fetch_vehicles_fn
      )

    widget_instances = primary_departures_instances ++ secondary_departures_instances

    # If every rotation is showing OvernightDepartures, we don't need to render any route pills.
    if Enum.all?(widget_instances, &is_struct(&1, OvernightDepartures)) do
      Enum.map(widget_instances, &%{&1 | routes: []})
    else
      widget_instances
    end
  end

  defp sections_data_to_departure_instances(
         sections_data,
         config,
         slot_ids,
         now,
         fetch_schedules_fn,
         fetch_vehicles_fn
       ) do
    sections =
      Enum.map(
        sections_data,
        &get_departure_instance_for_section(
          &1,
          length(sections_data) == 1,
          now,
          fetch_schedules_fn,
          fetch_vehicles_fn
        )
      )

    Enum.map(slot_ids, fn slot_id ->
      cond do
        Enum.all?(sections, &(&1.type == :no_data_section)) ->
          %DeparturesNoData{
            screen: config,
            slot_name: slot_id
          }

        Enum.all?(sections, &(&1.type == :overnight_section)) ->
          %OvernightDepartures{
            screen: config,
            slot_names: [slot_id],
            routes: get_route_pills_for_rotation(sections)
          }

        true ->
          %DeparturesWidget{
            screen: config,
            section_data: sections,
            slot_names: [slot_id]
          }
      end
    end)
  end

  defp get_departure_instance_for_section(%{type: :no_data_section} = section, _, _, _, _),
    do: section

  defp get_departure_instance_for_section(
         %{
           departures: departures,
           alert_informed_entities: alert_informed_entities,
           headway: headway,
           stop_ids: stop_ids,
           routes: routes,
           params: params
         },
         is_only_section,
         now,
         fetch_schedules_fn,
         fetch_vehicles_fn
       ) do
    routes_with_live_departures =
      departures |> Enum.map(&{Departure.route_id(&1), Departure.direction_id(&1)}) |> Enum.uniq()

    overnight_schedules_for_section =
      get_overnight_schedules_for_section(
        routes_with_live_departures,
        params,
        routes,
        alert_informed_entities,
        now,
        fetch_schedules_fn,
        fetch_vehicles_fn
      )

    headway_mode = get_headway_mode(stop_ids, headway, alert_informed_entities, now)

    cond do
      # All routes in section are overnight
      overnight_schedules_for_section != [] and departures == [] ->
        %{type: :overnight_section, routes: routes}

      # There are still predictions to show
      headway_mode == :inactive ->
        # Add overnight departures to the end.
        # This allows overnight departures to appear as we start to run out of predictions to show.
        departures = departures ++ overnight_schedules_for_section

        visible_departures =
          if is_only_section do
            Enum.take(departures, 4)
          else
            Enum.take(departures, 2)
          end

        %{type: :normal_section, rows: visible_departures}

      # Headway mode
      true ->
        {:active, time_range, headsign} = headway_mode

        %{
          type: :headway_section,
          route: get_section_route_from_entities(stop_ids, alert_informed_entities),
          time_range: time_range,
          headsign: headsign
        }
    end
  end

  defp get_sections_data(
         sections,
         fetch_section_departures_fn,
         fetch_alerts_fn,
         create_station_with_routes_map_fn,
         now
       ) do
    sections
    |> Task.async_stream(fn %Section{
                              query: %Query{
                                params: %Params{stop_ids: stop_ids} = params
                              },
                              headway: headway,
                              bidirectional: is_bidirectional
                            } = section ->
      routes = get_routes_serving_section(params, create_station_with_routes_map_fn)
      # DUP sections will always show one mode.
      # For subway, each route will have its own section.
      # If the stop is served by two different subway/light rail routes, route_ids must be populated for each section
      # Otherwise, we only need the first route in the list of routes serving the stop.
      primary_route_for_section = List.first(routes)

      # If we know the predictions are unreliable, don't even bother fetching them.
      if Screens.Config.State.mode_disabled?(primary_route_for_section.type) do
        %{type: :no_data_section, route: primary_route_for_section}
      else
        section_departures =
          case fetch_section_departures_fn.(section) do
            {:ok, []} ->
              []

            {:ok, section_departures} ->
              # If the section is configured as bidirectional,
              # it needs to show one departure in each direction
              if is_bidirectional,
                do: get_bidirectional_departures(section_departures),
                else: section_departures

            _ ->
              []
          end

        alert_informed_entities = get_section_entities(params, fetch_alerts_fn, now)

        %{
          departures: section_departures,
          alert_informed_entities: alert_informed_entities,
          headway: headway,
          stop_ids: stop_ids,
          routes: routes,
          params: params
        }
      end
    end)
    |> Enum.map(fn {:ok, data} -> data end)
  end

  defp get_section_route_from_entities(
         ["place-" <> _ = stop_id],
         informed_entities
       ) do
    Enum.find_value(informed_entities, "", fn
      %{route: route, stop: ^stop_id} -> route
      _ -> nil
    end)
  end

  defp get_section_route_from_entities(_, _), do: nil

  defp get_bidirectional_departures(section_departures) do
    first_row = List.first(section_departures)
    first_direction_id = Departure.direction_id(first_row)

    second_row =
      Enum.find(section_departures, Enum.at(section_departures, 1), fn departure ->
        Departure.direction_id(departure) === 1 - first_direction_id
      end)

    [first_row] ++ [second_row]
  end

  defp get_section_entities(
         %Params{
           stop_ids: stop_ids,
           route_ids: route_ids,
           direction_id: direction_id
         },
         fetch_alerts_fn,
         now
       ) do
    alert_fetch_params = [
      direction_id: direction_id,
      route_ids: route_ids,
      stop_ids: stop_ids,
      route_types: [:light_rail, :subway]
    ]

    # This section gets alert entities, which are used to decide whether we should be in headway mode or overnight mode
    alert_fetch_params
    |> fetch_alerts_fn.()
    |> Enum.filter(fn
      # Show a headway message only during shuttles and suspensions at temporary terminals.
      # https://www.notion.so/mbta-downtown-crossing/Departures-Widget-Specification-20da46cd70a44192a568e49ea47e09ac?pvs=4#e43086abaadd465ea8072502d6980d8d
      %Alert{effect: effect} = alert when effect in [:suspension, :shuttle] ->
        Alert.happening_now?(alert, now)

      _ ->
        false
    end)
    # Condense all alerts into just a list of informed entities
    # This will help us decide whether a headway in one direction is still useful
    # if there are two alerts that could be in different directions.
    |> Enum.reduce([], fn alert, acc -> acc ++ alert.informed_entities end)
    |> Enum.uniq()
  end

  defp get_headway_mode(_, _, [], _), do: :inactive

  defp get_headway_mode(
         stop_ids,
         %Headway{headway_id: headway_id},
         informed_entities,
         current_time
       ) do
    # Use all informed_entities from relevant alerts to decide whether there's
    # any reason to go into headway mode.
    # For example, a NB suspension and SB shuttle from Aquarium shouldn't use headway mode
    # but if all the WB branches are shuttling at Kenmore, there should be a headway
    interpreted_alert = interpret_entities(informed_entities, stop_ids)

    headway_mode? =
      temporary_terminal?(interpreted_alert) and
        not (branch_station?(stop_ids) and branch_alert?(interpreted_alert))

    if headway_mode? do
      time_ranges = SignsUiConfig.State.time_ranges(headway_id)
      current_time_period = Screens.Util.time_period(current_time)

      case time_ranges do
        %{^current_time_period => {lo, hi}} ->
          {:active, {lo, hi}, interpreted_alert.headsign}

        _ ->
          :inactive
      end
    else
      :inactive
    end
  end

  # NB: There aren't currently any DUPs at permanent terminals, so we assume all
  # terminals are temporary. In the future, we'll need to check that the boundary
  # isn't a normal terminal.
  defp temporary_terminal?(%{region: :boundary}), do: true
  defp temporary_terminal?(_), do: false

  defp branch_station?(stop_ids) do
    branch_stations = Application.get_env(:screens, :dup_headway_branch_stations)

    case stop_ids do
      [parent_station_id] -> parent_station_id in MapSet.new(branch_stations)
      _ -> false
    end
  end

  defp branch_alert?(%{headsign: headsign}) do
    branch_terminals = Application.get_env(:screens, :dup_headway_branch_terminals)
    headsign in MapSet.new(branch_terminals)
  end

  defp interpret_entities(entities, [parent_stop_id]) do
    informed_stop_ids = Enum.into(entities, MapSet.new(), & &1.stop)

    {region, headsign} =
      :screens
      |> Application.get_env(:dup_alert_headsign_matchers)
      |> Map.get(parent_stop_id)
      |> Enum.find_value({:inside, nil}, fn
        %{
          informed: informed,
          not_informed: not_informed,
          headway_headsign: headsign
        } ->
          if alert_region_match?(
               Util.to_set(informed),
               Util.to_set(not_informed),
               informed_stop_ids
             ),
             do: {:boundary, headsign},
             else: false

        _ ->
          false
      end)

    %{
      region: region,
      headsign: headsign
    }
  end

  defp alert_region_match?(informed, not_informed, informed_stop_ids) do
    MapSet.subset?(informed, informed_stop_ids) and
      MapSet.disjoint?(not_informed, informed_stop_ids)
  end

  # If we are currently overnight, returns the first schedule of the day for each route_id and direction for each stop.
  # Otherwise, return an empty list.
  defp get_overnight_schedules_for_section(
         routes_with_live_departures,
         stop_ids,
         routes_serving_section,
         alert_informed_entities,
         now,
         fetch_schedules_fn,
         fetch_vehicles_fn
       )

  # No predictions AND no active alerts for the section
  defp get_overnight_schedules_for_section(
         routes_with_live_departures,
         params,
         routes,
         [],
         now,
         fetch_schedules_fn,
         _
       ) do
    {today_schedules, tomorrow_schedules} =
      get_today_tomorrow_schedules(
        Map.from_struct(params),
        fetch_schedules_fn,
        now,
        Enum.map(routes, & &1.id)
      )

    # Get schedules for each route_id in config
    today_schedules
    |> Enum.map(&{&1.route.id, &1.direction_id})
    |> Enum.uniq()
    |> Enum.reject(&(&1 in routes_with_live_departures))
    |> Enum.map(fn {route_id, direction_id} ->
      # This variable will be used when now is after 3am.
      first_schedule_today =
        Enum.find(
          today_schedules,
          &(&1.route.id == route_id and &1.direction_id == direction_id)
        )

      last_schedule_today =
        Enum.find(
          Enum.reverse(today_schedules),
          &(&1.route.id == route_id and &1.direction_id == direction_id)
        )

      first_schedule_tomorrow =
        Enum.find(
          tomorrow_schedules,
          &(&1.route.id == route_id and &1.direction_id == direction_id)
        )

      get_overnight_departure_for_route(
        first_schedule_today,
        last_schedule_today,
        first_schedule_tomorrow,
        route_id,
        direction_id,
        now
      )
    end)
    # Routes not in overnight mode will be nil. Can ignore those.
    |> Enum.reject(&is_nil/1)
    |> Enum.sort_by(fn %Departure{schedule: schedule} -> schedule.departure_time end)
  end

  defp get_overnight_schedules_for_section(
         routes_with_live_departures,
         params,
         [%{type: type} | _] = routes,
         alert_informed_entities,
         now,
         fetch_schedules_fn,
         fetch_vehicles_fn
       )
       when type in [:subway, :light_rail] do
    informed_route = get_section_route_from_entities(params.stop_ids, alert_informed_entities)
    # If there are no vehicles operating on the route, assume we are overnight.
    if not is_nil(informed_route) and fetch_vehicles_fn.(informed_route, nil) == [] do
      get_overnight_schedules_for_section(
        routes_with_live_departures,
        params,
        routes,
        [],
        now,
        fetch_schedules_fn,
        fetch_vehicles_fn
      )
    else
      []
    end
  end

  defp get_overnight_schedules_for_section(_, _, _, _, _, _, _), do: []

  # Verifies we are meeting the timeframe conditions for overnight mode and generates the departure widget
  defp get_overnight_departure_for_route(
         _first_schedule_today,
         nil,
         _first_schedule_tomorrow,
         route_id,
         direction_id,
         now
       ) do
    Logger.warn(
      "[get_overnight_schedules_for_section] last_schedule_today not found. route_id=#{route_id} direction_id=#{direction_id} now=#{now}"
    )

    nil
  end

  defp get_overnight_departure_for_route(
         first_schedule_today,
         last_schedule_today,
         first_schedule_tomorrow,
         route_id,
         direction_id,
         now
       ) do
    cond do
      is_nil(first_schedule_tomorrow) ->
        nil

      DateTime.compare(now, first_schedule_tomorrow.departure_time) == :gt ->
        Logger.warn(
          "[get_overnight_schedules_for_section] now is after first_schedule_tomorrow. route_id=#{route_id} direction_id=#{direction_id} now=#{now}"
        )

        nil

      # Before 3am and between the `departure_time` for today's last schedule and tomorrow's first schedule
      DateTime.compare(now, last_schedule_today.departure_time) == :gt and
          DateTime.compare(now, first_schedule_tomorrow.departure_time) == :lt ->
        %Departure{schedule: first_schedule_tomorrow}

      # After 3am but before the first scheduled trip of the day.
      not is_nil(first_schedule_today) and
          DateTime.compare(now, first_schedule_today.departure_time) == :lt ->
        %Departure{schedule: first_schedule_today}

      true ->
        nil
    end
  end

  defp get_today_tomorrow_schedules(
         fetch_params,
         fetch_schedules_fn,
         now,
         route_ids_serving_section
       ) do
    today =
      case fetch_schedules_fn.(fetch_params, now) do
        {:ok, schedules} when schedules != [] ->
          Enum.filter(schedules, &(&1.route.id in route_ids_serving_section))

        # fetch error or empty schedules
        _ ->
          []
      end

    tomorrow =
      case fetch_schedules_fn.(fetch_params, Util.get_service_date_tomorrow(now)) do
        {:ok, schedules} when schedules != [] ->
          Enum.filter(schedules, &(&1.route.id in route_ids_serving_section))

        # fetch error or empty schedules
        _ ->
          []
      end

    {today, tomorrow}
  end

  defp get_routes_serving_section(
         %{route_ids: route_ids, stop_ids: stop_ids},
         create_station_with_routes_map_fn
       ) do
    routes =
      stop_ids
      |> Enum.flat_map(&create_station_with_routes_map_fn.(&1))
      |> Enum.uniq()

    if route_ids == [] do
      routes
    else
      Enum.filter(routes, &(&1.id in route_ids))
    end
  end

  defp get_route_pills_for_rotation(sections) do
    sections
    |> Enum.flat_map(fn %{routes: routes} ->
      Enum.map(routes, &Route.get_icon_or_color_from_route/1)
    end)
    |> Enum.uniq()
  end
end
