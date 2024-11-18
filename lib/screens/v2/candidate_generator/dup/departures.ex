defmodule Screens.V2.CandidateGenerator.Dup.Departures do
  @moduledoc false

  require Logger

  alias Screens.Alerts.Alert
  alias Screens.Routes.Route
  alias Screens.Util
  alias Screens.V2.CandidateGenerator.Widgets
  alias Screens.V2.Departure
  alias Screens.V2.WidgetInstance.Departures, as: DeparturesWidget
  alias Screens.V2.WidgetInstance.{DeparturesNoData, OvernightDepartures}
  alias ScreensConfig.Screen
  alias ScreensConfig.V2.Departures
  alias ScreensConfig.V2.Departures.{Header, Layout, Query, Section}
  alias ScreensConfig.V2.Departures.Query.Params
  alias ScreensConfig.V2.Dup

  import Screens.Inject

  @headways injected(Screens.Headways)

  def departures_instances(
        %Screen{
          app_params: %Dup{
            primary_departures: %Departures{sections: primary_sections},
            secondary_departures: %Departures{sections: secondary_sections}
          }
        } = config,
        now,
        fetch_departures_fn \\ &Departure.fetch/2,
        fetch_alerts_fn \\ &Alert.fetch_or_empty_list/1,
        fetch_schedules_fn \\ &Screens.Schedules.Schedule.fetch/2,
        fetch_routes_fn \\ &Screens.Routes.Route.fetch/1,
        fetch_vehicles_fn \\ &Screens.Vehicles.Vehicle.by_route_and_direction/2
      ) do
    primary_departures_instances =
      primary_sections
      |> get_sections_data(
        fetch_departures_fn,
        fetch_alerts_fn,
        fetch_routes_fn,
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
        fetch_departures_fn,
        fetch_alerts_fn,
        fetch_routes_fn,
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
            slot_names: [slot_id],
            now: now
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
      departures
      |> Enum.map(&{Departure.route(&1).id, Departure.direction_id(&1)})
      |> Enum.uniq()

    # Check if there is any room for overnight rows before running the logic.
    overnight_schedules_for_section =
      if (is_only_section and length(departures) >= 4) or length(departures) >= 2 do
        []
      else
        get_overnight_schedules_for_section(
          routes_with_live_departures,
          params,
          routes,
          alert_informed_entities,
          now,
          fetch_schedules_fn,
          fetch_vehicles_fn
        )
      end

    headway_mode = get_headway_mode(stop_ids, routes, alert_informed_entities, now)

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

        # DUPs don't support Layout or Header for now
        %{type: :normal_section, rows: visible_departures, layout: %Layout{}, header: %Header{}}

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
         fetch_departures_fn,
         fetch_alerts_fn,
         fetch_routes_fn,
         now
       ) do
    Screens.Telemetry.span(
      [:screens, :v2, :candidate_generator, :dup, :departures, :get_sections_data],
      fn ->
        ctx = Screens.Telemetry.context()

        sections
        |> Task.async_stream(
          &get_section_data(
            &1,
            fetch_departures_fn,
            fetch_alerts_fn,
            fetch_routes_fn,
            now,
            ctx
          ),
          on_timeout: :kill_task
        )
        |> Enum.map(fn
          {:ok, data} ->
            data

          {:exit, reason} ->
            ctx =
              Screens.Telemetry.context()
              |> to_log()

            Logger.error(["event=get_section_data.exit reason=#{reason} ", ctx])
            raise "Failed to get section data"
        end)
      end
    )
  end

  defp get_section_data(
         %Section{query: %Query{params: %Params{stop_ids: stop_ids} = params}} = section,
         fetch_departures_fn,
         fetch_alerts_fn,
         fetch_routes_fn,
         now,
         ctx
       ) do
    Screens.Telemetry.span(
      [:screens, :v2, :candidate_generator, :dup, :departures, :get_section_data],
      ctx,
      fn ->
        routes = get_routes_serving_section(params, fetch_routes_fn)
        # DUP sections will always show no more than one mode.
        # For subway, each route will have its own section.
        # If the stop is served by two different subway/light rail routes, route_ids must be populated for each section
        # Otherwise, we only need the first route in the list of routes serving the stop.
        primary_route_for_section = List.first(routes)

        disabled_modes = Screens.Config.Cache.disabled_modes()

        # If we know the predictions are unreliable, don't even bother fetching them.
        if is_nil(primary_route_for_section) or
             primary_route_for_section.type in disabled_modes do
          %{type: :no_data_section, route: primary_route_for_section}
        else
          section_departures =
            case Widgets.Departures.fetch_section_departures(
                   section,
                   disabled_modes,
                   fetch_departures_fn
                 ) do
              {:ok, departures} -> departures
              :error -> []
            end

          alert_informed_entities = get_section_entities(params, fetch_alerts_fn, now)

          %{
            departures: section_departures,
            alert_informed_entities: alert_informed_entities,
            stop_ids: stop_ids,
            routes: routes,
            params: params
          }
        end
      end
    )
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

  defp get_headway_mode(stop_ids, routes, informed_entities, current_time) do
    # Use all informed_entities from relevant alerts to decide whether there's
    # any reason to go into headway mode.
    # For example, a NB suspension and SB shuttle from Aquarium shouldn't use headway mode
    # but if all the WB branches are shuttling at Kenmore, there should be a headway
    interpreted_alert = interpret_entities(informed_entities, stop_ids)

    headway_mode? =
      temporary_terminal?(interpreted_alert) and
        not (branch_station?(stop_ids) and branch_alert?(interpreted_alert))

    if headway_mode? do
      all_headways =
        for stop_id <- stop_ids, %{id: route_id} <- routes do
          @headways.get_with_route(stop_id, route_id, current_time)
        end

      case Enum.uniq(all_headways) do
        [{lo, hi}] -> {:active, {lo, hi}, interpreted_alert.headsign}
        _ -> :inactive
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

  defp interpret_entities(entities, parent_stop_ids) do
    informed_stop_ids = Enum.into(entities, MapSet.new(), & &1.stop)
    parent_stop_id = List.first(parent_stop_ids)

    {region, headsign} =
      :screens
      |> Application.get_env(:dup_alert_headsign_matchers)
      |> Map.get(parent_stop_id, [])
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
         first_schedule_today,
         last_schedule_today,
         _first_schedule_tomorrow,
         route_id,
         direction_id,
         now
       )
       when is_nil(first_schedule_today) or is_nil(last_schedule_today) do
    Logger.info(
      "[get_overnight_schedules_for_section] No schedules for today found. route_id=#{route_id} direction_id=#{direction_id} now=#{now}"
    )

    nil
  end

  # If now is after today's last schedule and there are no schedules tomorrow,
  # we still want a departure row without a time (will show a moon icon)
  defp get_overnight_departure_for_route(
         first_schedule_today,
         last_schedule_today,
         nil,
         _route_id,
         _direction_id,
         now
       ) do
    if DateTime.compare(now, last_schedule_today.departure_time) == :gt or
         DateTime.compare(now, first_schedule_today.departure_time) == :lt do
      # nil/nil acts as a flag for the serializer to produce an `overnight` departure time
      %Departure{
        schedule: %{last_schedule_today | departure_time: nil, arrival_time: nil}
      }
    else
      nil
    end
  end

  # If now is before any of today's schedules or after any of tomorrow's (should never happen but just in case)
  # we do not display overnight mode.
  defp get_overnight_departure_for_route(
         first_schedule_today,
         last_schedule_today,
         first_schedule_tomorrow,
         route_id,
         direction_id,
         now
       ) do
    cond do
      DateTime.compare(now, first_schedule_tomorrow.departure_time) == :gt ->
        Logger.warning(
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
         fetch_routes_fn
       ) do
    routes =
      case fetch_routes_fn.(%{stop_ids: stop_ids}) do
        {:ok, routes} -> routes
        :error -> []
      end

    if route_ids == [] do
      routes
    else
      Enum.filter(routes, &(&1.id in route_ids))
    end
  end

  defp get_route_pills_for_rotation(sections) do
    sections
    |> Enum.flat_map(fn %{routes: routes} -> Enum.map(routes, &Route.icon/1) end)
    |> Enum.uniq()
  end

  defp to_log(map) do
    Enum.map_join(map, " ", fn {k, v} -> "#{k}=#{v}" end)
  end
end
