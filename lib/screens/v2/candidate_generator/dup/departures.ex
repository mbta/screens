defmodule Screens.V2.CandidateGenerator.Dup.Departures do
  @moduledoc false

  alias Screens.Alerts.Alert
  alias Screens.Config.Screen
  alias Screens.Config.V2.Departures
  alias Screens.Config.V2.Departures.{Headway, Query, Section}
  alias Screens.Config.V2.Departures.Query.Params
  alias Screens.Config.V2.Dup
  alias Screens.Schedules.Schedule
  alias Screens.V2.Departure
  alias Screens.SignsUiConfig
  alias Screens.Util
  alias Screens.V2.CandidateGenerator.Widgets
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
        create_station_with_routes_map_fn \\ &Screens.Stops.Stop.create_station_with_routes_map/1
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
        [:main_content_zero, :main_content_one],
        now,
        fetch_schedules_fn
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
        [:main_content_two],
        now,
        fetch_schedules_fn
      )

    primary_departures_instances ++ secondary_departures_instances
  end

  defp sections_data_to_departure_instances(
         sections_data,
         config,
         slot_ids,
         now,
         fetch_schedules_fn
       ) do
    sections =
      Enum.map(
        sections_data,
        &get_departure_instance_for_section(
          &1,
          length(sections_data) == 1,
          now,
          fetch_schedules_fn
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
          route_pills =
            sections
            |> Enum.flat_map(fn %{routes: routes} ->
              Enum.map(routes, fn
                %{type: :rail} -> :cr
                %{short_name: "SL" <> _} -> :silver
                %{type: :bus} -> :bus
                %{id: id} -> Util.get_color_for_route(id)
                _ -> nil
              end)
            end)
            |> Enum.uniq()

          %OvernightDepartures{screen: config, slot_names: [slot_id], routes: route_pills}

        true ->
          %DeparturesWidget{
            screen: config,
            section_data: sections,
            slot_names: [slot_id]
          }
      end
    end)
  end

  defp get_departure_instance_for_section(%{type: :no_data_section} = section, _, _, _),
    do: section

  defp get_departure_instance_for_section(
         %{
           departures: departures,
           alert: alert,
           headway: headway,
           stop_ids: stop_ids,
           routes: routes
         },
         is_only_section,
         now,
         fetch_schedules_fn
       ) do
    routes_with_live_departures = departures |> Enum.map(&Departure.route_id/1) |> Enum.uniq()

    overnight_schedules_for_section =
      get_overnight_schedules_for_section(
        routes_with_live_departures,
        stop_ids,
        routes,
        alert,
        now,
        fetch_schedules_fn
      )

    headway_mode = get_headway_mode(stop_ids, headway, alert, now)

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

        if visible_departures == [] do
          %{type: :no_data_section, route: List.first(routes)}
        else
          %{type: :normal_section, rows: visible_departures}
        end

      # Headway mode
      true ->
        {:active, time_range, headsign} = headway_mode

        %{
          type: :headway_section,
          pill: get_section_route_from_alert(stop_ids, alert),
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
                              headway: headway
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
            {:ok, section_departures} -> section_departures
            _ -> []
          end

        section_alert = get_section_alert(params, fetch_alerts_fn, now)

        %{
          departures: section_departures,
          alert: section_alert,
          headway: headway,
          stop_ids: stop_ids,
          routes: routes
        }
      end
    end)
    |> Enum.map(fn {:ok, data} -> data end)
  end

  # Alert will only have a value for sections that are configured for a station's ID
  defp get_section_route_from_alert(
         ["place-" <> _ = stop_id],
         %Alert{informed_entities: informed_entities}
       ) do
    informed_entities
    |> Enum.find_value("", fn
      %{route: route, stop: ^stop_id} -> route
      _ -> nil
    end)
    |> String.downcase()
    |> String.to_atom()
  end

  defp get_section_route_from_alert(_, _), do: nil

  defp get_section_alert(
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
    |> List.first()
  end

  defp get_headway_mode(_, _, nil, _), do: :inactive

  defp get_headway_mode(
         stop_ids,
         %Headway{headway_id: headway_id},
         section_alert,
         current_time
       ) do
    interpreted_alert = interpret_alert(section_alert, stop_ids)

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

  defp interpret_alert(alert, [parent_stop_id]) do
    informed_stop_ids = Enum.into(alert.informed_entities, MapSet.new(), & &1.stop)

    {region, headsign} =
      :screens
      |> Application.get_env(:dup_alert_headsign_matchers)
      |> Map.get(parent_stop_id)
      |> Enum.find_value({:inside, nil}, fn {informed, not_informed, headsign} ->
        if alert_region_match?(
             Util.to_set(informed),
             Util.to_set(not_informed),
             informed_stop_ids
           ),
           do: {:boundary, headsign},
           else: false
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
         alert,
         now,
         fetch_schedules_fn
       )

  # No predictions AND no active alerts for the section
  defp get_overnight_schedules_for_section(
         routes_with_live_departures,
         stop_ids,
         [%{type: :bus} | _] = routes_serving_section,
         nil,
         now,
         fetch_schedules_fn
       ) do
    fetch_params = %{stop_ids: stop_ids}

    {today_schedules, tomorrow_schedules} =
      get_today_tomorrow_schedules(
        fetch_params,
        fetch_schedules_fn,
        Util.get_service_day_tomorrow(now)
      )

    # Get schedules for each route for all stop_ids in config
    routes_serving_section
    |> Enum.reject(&(&1.id in routes_with_live_departures))
    |> Enum.map(fn %{id: route_id} ->
      # If now is before any of today's schedules or after any of tomorrow's (should never happen but just in case),
      # we do not display overnight mode.

      last_schedule_today =
        Enum.find(
          today_schedules,
          struct(Schedule, departure_time: now),
          &(&1.route.id == route_id)
        )

      first_schedule_tomorrow =
        Enum.find(
          tomorrow_schedules,
          struct(Schedule, departure_time: now),
          &(&1.route.id == route_id)
        )
        |> IO.inspect()

      if DateTime.compare(now, last_schedule_today.departure_time) == :gt or
           DateTime.compare(now, first_schedule_tomorrow.departure_time) == :lt do
        %Departure{schedule: first_schedule_tomorrow}
      end
    end)
    # Routes not in overnight mode will be nil. Can ignore those.
    |> Enum.reject(&is_nil/1)
    |> Enum.sort_by(fn %Departure{schedule: schedule} -> schedule.departure_time end)
  end

  defp get_overnight_schedules_for_section(_, _, _, _, _, _), do: []

  defp get_today_tomorrow_schedules(fetch_params, fetch_schedules_fn, tomorrow) do
    today =
      case fetch_schedules_fn.(fetch_params, nil) do
        {:ok, schedules} when schedules != [] ->
          # We want the last schedules of the current day.
          # Need to reverse the list of fetched schedules so that List.first/1 looks at the correct time of day.
          Enum.reverse(schedules)

        # fetch error or empty schedules
        _ ->
          []
      end

    tomorrow =
      case fetch_schedules_fn.(fetch_params, tomorrow) do
        {:ok, schedules} when schedules != [] ->
          schedules

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
end
