defmodule Screens.V2.CandidateGenerator.Dup.Departures do
  @moduledoc false

  require Logger

  alias Screens.Alerts.{Alert, InformedEntity}
  alias Screens.LogScreenData
  alias Screens.Report
  alias Screens.Routes.Route
  alias Screens.Schedules.Schedule
  alias Screens.Stops.Stop
  alias Screens.Util
  alias Screens.V2.CandidateGenerator.Widgets
  alias Screens.V2.Departure
  alias Screens.V2.WidgetInstance.Departures, as: DeparturesWidget
  alias Screens.V2.WidgetInstance.{DeparturesNoData, OvernightDepartures}
  alias Screens.Vehicles.Vehicle
  alias ScreensConfig.{Departures, Screen}
  alias ScreensConfig.Departures.{Header, Layout, Query, Section}
  alias ScreensConfig.Departures.Query.Params
  alias ScreensConfig.Screen.Dup

  alias Screens.V2.WidgetInstance.Departures.{
    HeadwaySection,
    NoDataSection,
    NormalSection,
    OvernightSection
  }

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
    [primary_instance, secondary_instance] =
      Enum.map([primary_sections, secondary_sections], fn sections ->
        sections
        |> get_sections_data(fetch_departures_fn, fetch_alerts_fn, fetch_routes_fn, now)
        |> sections_data_to_instance_fn(config, now, fetch_schedules_fn, fetch_vehicles_fn)
      end)

    # When the secondary instance would not be displaying anything useful, make it a copy of the
    # primary instance.
    secondary_instance =
      if secondary_sections == [] or no_departures?(secondary_instance),
        do: primary_instance,
        else: secondary_instance

    primary_instances =
      Enum.map(
        [
          :main_content_zero,
          :main_content_one,
          :main_content_reduced_zero,
          :main_content_reduced_one
        ],
        &struct!(primary_instance, slot_names: [&1])
      )

    secondary_instances =
      Enum.map(
        [:main_content_two, :main_content_reduced_two],
        &struct!(secondary_instance, slot_names: [&1])
      )

    instances = primary_instances ++ secondary_instances

    cond do
      # If every rotation is showing OvernightDepartures, we don't need to render any route pills.
      Enum.all?(instances, &is_struct(&1, OvernightDepartures)) ->
        Enum.map(instances, &%OvernightDepartures{&1 | routes: []})

      # If every rotation consists entirely of NoDataSections, replace all with DeparturesNoData.
      Enum.all?(instances, &no_departures?/1) ->
        Enum.map(instances, fn %DeparturesWidget{screen: screen, slot_names: [slot_name]} ->
          %DeparturesNoData{screen: screen, slot_name: slot_name}
        end)

      true ->
        instances
    end
  end

  defp no_departures?(%DeparturesWidget{sections: sections}),
    do: Enum.all?(sections, &is_struct(&1, NoDataSection))

  defp no_departures?(_widget_instance), do: false

  @typep section_data ::
           %{type: :no_data_section, route: Route.t()}
           | %{
               departures: [Departure.t()],
               alert_informed_entities: [InformedEntity.t()],
               stop_ids: [Stop.id()],
               routes: [Route.t()],
               params: Params.t()
             }

  @spec sections_data_to_instance_fn(
          [section_data()],
          Screen.t(),
          DateTime.t(),
          Schedule.fetch_with_date(),
          Vehicle.by_route_and_direction()
        ) :: DeparturesWidget.t() | OvernightDepartures.t()
  defp sections_data_to_instance_fn(
         sections_data,
         config,
         now,
         fetch_schedules_fn,
         fetch_vehicles_fn
       ) do
    is_only_section = match?([_], sections_data)

    sections =
      Enum.map(
        sections_data,
        &get_section_instance(
          &1,
          is_only_section,
          now,
          fetch_schedules_fn,
          fetch_vehicles_fn,
          config.name
        )
      )

    # NB: No slot names provided here (defaults to `[]`) as they will be filled in depending on
    # whether the widget is placed in the primary or secondary slots.
    if Enum.any?(sections) and Enum.all?(sections, &is_struct(&1, OvernightSection)) do
      route_pills = get_route_pills_for_rotation(sections)
      %OvernightDepartures{screen: config, routes: route_pills}
    else
      %DeparturesWidget{screen: config, sections: sections, now: now}
    end
  end

  @spec get_section_instance(
          section_data(),
          boolean(),
          DateTime.t(),
          Schedule.fetch_with_date(),
          Vehicle.by_route_and_direction(),
          String.t()
        ) :: DeparturesWidget.section()
  defp get_section_instance(
         %{type: :no_data_section, route: route},
         _is_only_section,
         _now,
         _fetch_schedules_fn,
         _fetch_vehicles_fn,
         _screen_name
       ),
       do: %NoDataSection{route: route}

  defp get_section_instance(
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
         fetch_vehicles_fn,
         screen_name
       ) do
    routes_with_live_departures =
      departures
      |> Enum.map(&{Departure.route(&1).id, Departure.direction_id(&1)})
      |> Enum.uniq()

    max_visible_departures = if is_only_section, do: 2, else: 4

    # Check if there is any room for overnight rows before running the logic.
    {section_contains_active_route, overnight_schedules_for_section} =
      if length(departures) >= max_visible_departures do
        {false, []}
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
      # All routes in the section are disabled, so no departures are expected.
      # In this case, the alerts widget will display info on the closure, so we return an empty section.
      departures == [] and
          section_routes_disabled?(routes, params.direction_id, alert_informed_entities) ->
        %NormalSection{rows: departures, layout: %Layout{}, header: %Header{}}

      # No remaining departures or active routes, but we do have routes with overnight schedules
      # Show a takeover Overnight section for the given route types
      departures == [] and !section_contains_active_route and
          overnight_schedules_for_section != [] ->
        # Temporarily return a no data section here b/c of an edge case with prediction suppression
        %NoDataSection{route: hd(routes)}

      # Headway mode
      headway_mode != :inactive ->
        {:active, time_range, headsign} = headway_mode

        %HeadwaySection{
          route: get_section_route_from_entities(stop_ids, alert_informed_entities),
          time_range: time_range,
          headsign: headsign
        }

      # No departures to show and no headway mode
      departures == [] ->
        %NoDataSection{route: hd(routes)}

      # Normal departures mode
      true ->
        # Add overnight departures to the end.
        # This allows overnight departures to appear as we start to run out of predictions to show.
        departures =
          if length(departures) < max_visible_departures and overnight_schedules_for_section != [] do
            # Temporary logs for insight into a bug with incorrect departure for next day being shown
            # https://app.asana.com/1/15492006741476/project/1185117109217413/task/1210559658847355
            LogScreenData.log_dup_data(screen_name, departures, overnight_schedules_for_section)
            departures ++ overnight_schedules_for_section
          else
            departures
          end

        visible_departures = Enum.take(departures, max_visible_departures)

        # DUPs don't support Layout or Header for now
        %NormalSection{rows: visible_departures, layout: %Layout{}, header: %Header{}}
    end
  end

  # Determines if the active alerts for a section apply to all routes that are enabled in the section
  @spec section_routes_disabled?([Route.t()], 0 | 1 | :both, [InformedEntity.t()]) :: boolean()
  defp section_routes_disabled?(routes, direction_id, alert_informed_entities) do
    case alert_informed_entities do
      [] ->
        false

      _ ->
        # Normalize direction_id. Typically `nil` in Informed Entity represents both directions
        direction_id =
          case direction_id do
            :both -> nil
            _ -> direction_id
          end

        # For each route, verify if there is an associated Informed Entity
        routes
        |> Enum.map(& &1.id)
        |> Enum.all?(fn route_id ->
          Enum.any?(alert_informed_entities, fn entity ->
            InformedEntity.present_alert_for_route?(entity, route_id, direction_id)
          end)
        end)
    end
  end

  @spec get_sections_data(
          [Section.t()],
          Departure.fetch(),
          Alert.fetch(),
          Route.fetch(),
          now :: DateTime.t()
        ) :: [section_data()]
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
    # Also used to check if no departures are expected for a section because of closures to all routes/directions
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

  # Return 'overnight' Departures from `get_overnight_schedules_for_section` to potentially show
  # if one of the following is true for a given route_id/direction_id combo:
  # 1. Service for the route is done for the day, so we may display the first departure of tomorrow.
  # 2. Service for the route has not started for the day, so we may display the first departure of today.
  # 3. Service for the route is done for the day and not scheduled tomorrow
  #    (possible for CR/buses/routes with interruptions tomorrow), so return a Departure
  #    with nil departure_time and arrival_time to be handled by the serializer.
  #
  # Returns a tuple where:
  #  - First value is a boolean to track if there are any remaining scheduled trips for the section.
  #  - Second value is a list of Departure Schedules to potentially show on screen given enough space.
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
    overnight_schedules =
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

    # We flag if any routes have service ongoing so the section doesn't show as fully overnight
    is_sections_service_active = Enum.any?(overnight_schedules, &(&1 == :route_service_ongoing))

    {is_sections_service_active,
     overnight_schedules
     # Routes not in overnight mode will be nil. Can ignore those.
     |> Enum.reject(fn elem -> is_nil(elem) or elem == :route_service_ongoing end)
     |> Enum.sort_by(fn %Departure{schedule: %Schedule{departure_time: dt}} -> dt end)}
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
      {false, []}
    end
  end

  defp get_overnight_schedules_for_section(_, _, _, _, _, _, _), do: {false, []}

  # Verifies we are meeting the timeframe conditions for overnight mode and generates the departure widget
  defp get_overnight_departure_for_route(
         first_schedule_today,
         last_schedule_today,
         _first_schedule_tomorrow,
         route_id,
         direction_id,
         _now
       )
       when is_nil(first_schedule_today) or is_nil(last_schedule_today) do
    Report.warning("dup_overnight_no_first_last_schedule",
      route_id: route_id,
      direction_id: direction_id
    )

    nil
  end

  defp get_overnight_departure_for_route(
         first_schedule_today,
         last_schedule_today,
         nil,
         _route_id,
         _direction_id,
         now
       ) do
    # If now is after today's last schedule and there are no schedules tomorrow,
    # we still want a departure row without a time (will show a moon icon)
    if DateTime.compare(now, last_schedule_today.departure_time) == :gt or
         DateTime.compare(now, first_schedule_today.departure_time) == :lt do
      # nil/nil acts as a flag for the serializer to produce an `overnight` departure time
      %Departure{
        schedule: %{last_schedule_today | departure_time: nil, arrival_time: nil}
      }
    else
      # Return an atom so we can track that there is still a departure for this route during today's service.
      :route_service_ongoing
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
        Report.warning("dup_overnight_after_first_schedule",
          route_id: route_id,
          direction_id: direction_id
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

      # Before 3am and before the last scheduled trip of the day.
      # Return an atom so we can track that there is still a departure for this route during today's service.
      DateTime.compare(now, last_schedule_today.departure_time) == :lt ->
        :route_service_ongoing

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
      case fetch_schedules_fn.(fetch_params, now |> Util.service_date() |> Date.add(1)) do
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
    |> Enum.flat_map(fn %OvernightSection{routes: routes} -> Enum.map(routes, &Route.icon/1) end)
    |> Enum.uniq()
  end

  defp to_log(map) do
    Enum.map_join(map, " ", fn {k, v} -> "#{k}=#{v}" end)
  end
end
