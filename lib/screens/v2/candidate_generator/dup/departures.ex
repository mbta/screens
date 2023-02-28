defmodule Screens.V2.CandidateGenerator.Dup.Departures do
  @moduledoc false

  alias Screens.Alerts.Alert
  alias Screens.Config.Screen
  alias Screens.Config.V2.Departures
  alias Screens.Config.V2.Departures.{Headway, Query, Section}
  alias Screens.Config.V2.Departures.Query.Params
  alias Screens.Config.V2.Dup
  alias Screens.Schedules.Schedule
  alias Screens.SignsUiConfig
  alias Screens.Util
  alias Screens.V2.CandidateGenerator.Widgets
  alias Screens.V2.Departure
  alias Screens.V2.WidgetInstance.Departures, as: DeparturesWidget
  alias Screens.V2.WidgetInstance.DeparturesNoData

  @branch_stations ["place-kencl", "place-jfk", "place-coecl"]
  @branch_terminals [
    "Boston College",
    "Cleveland Circle",
    "Riverside",
    "Heath Street",
    "Ashmont",
    "Braintree"
  ]

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
        fetch_schedules_fn \\ &Screens.Schedules.Schedule.fetch/2
      ) do
    primary_departures_instances =
      primary_sections
      |> get_sections_data(fetch_section_departures_fn, fetch_alerts_fn, now)
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
      |> get_sections_data(fetch_section_departures_fn, fetch_alerts_fn, now)
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
    if Enum.any?(sections_data, &(&1 == :error)) do
      %DeparturesNoData{screen: config, show_alternatives?: true}
    else
      sections =
        Enum.map(sections_data, fn %{
                                     departures: departures,
                                     alert: alert,
                                     headway: headway,
                                     stop_ids: stop_ids,
                                     params: params
                                   } ->
          overnight_schedules_for_section =
            get_overnight_schedules_for_section([], params, nil, now, fetch_schedules_fn)

          departures =
            if show_overnight_mode?(overnight_schedules_for_section) do
              overnight_schedules_for_section
            else
              departures
            end

          visible_departures =
            if length(sections_data) > 1 do
              Enum.take(departures, 2)
            else
              Enum.take(departures, 4)
            end

          case get_headway_mode(stop_ids, headway, alert, now) do
            {:active, time_range, headsign} ->
              %{
                type: :headway_section,
                pill: get_section_route_from_alert(stop_ids, alert),
                time_range: time_range,
                headsign: headsign
              }

            :inactive ->
              %{type: :normal_section, rows: visible_departures}
          end
        end)

      Enum.map(slot_ids, fn slot_id ->
        %DeparturesWidget{
          screen: config,
          section_data: sections,
          slot_names: [slot_id]
        }
      end)
    end
  end

  defp get_sections_data(sections, fetch_section_departures_fn, fetch_alerts_fn, now) do
    sections
    |> Task.async_stream(fn %Section{
                              query: %Query{params: %Params{stop_ids: stop_ids} = params},
                              headway: headway
                            } = section ->
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
        params: params
      }
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
    case stop_ids do
      [parent_station_id] -> parent_station_id in MapSet.new(@branch_stations)
      _ -> false
    end
  end

  defp branch_alert?(%{headsign: headsign}) do
    headsign in MapSet.new(@branch_terminals)
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

  defp show_overnight_mode?(overnight_schedules) do
    not Enum.any?(overnight_schedules, &is_nil/1) and overnight_schedules != []
  end

  # No predictions AND no active alerts for the section
  defp get_overnight_schedules_for_section(
         [],
         %{stop_ids: stop_ids, direction_id: direction_id, route_ids: route_ids},
         nil,
         now,
         fetch_schedules_fn
       ) do
    routes_for_section =
      if route_ids == [] do
        Screens.Stops.Stop.get_routes_serving_stop_ids(stop_ids)
      else
        route_ids
      end

    Enum.flat_map(routes_for_section, fn route_id ->
      fetch_params = %{stop_ids: stop_ids, direction_id: direction_id, route_ids: [route_id]}

      last_schedules_today = get_schedules(fetch_params, fetch_schedules_fn, now)

      first_schedules_tomorrow =
        get_schedules(fetch_params, fetch_schedules_fn, now, Util.get_service_day_tomorrow(now))

      if Enum.all?(last_schedules_today, &(DateTime.compare(now, &1.departure_time) == :gt)) and
           Enum.all?(first_schedules_tomorrow, &(DateTime.compare(now, &1.departure_time) == :lt)) do
        Enum.map(first_schedules_tomorrow, fn schedule -> %Departure{schedule: schedule} end)
      else
        []
      end
    end)
  end

  defp get_overnight_schedules_for_section(_, _, _, _, _), do: []

  defp get_schedules(fetch_params, fetch_schedules_fn, now, tomorrow \\ nil) do
    schedules =
      case fetch_schedules_fn.(fetch_params, tomorrow) do
        {:ok, schedules} when schedules != [] ->
          schedules_reversed = Enum.reverse(schedules)

          # Get the schedule
          if fetch_params.direction_id == :both do
            schedule_0 =
              schedules_reversed
              |> Enum.filter(&(&1.direction_id == 0))
              |> List.first()

            schedule_1 =
              schedules_reversed
              |> Enum.filter(&(&1.direction_id == 1))
              |> List.first()

            [schedule_0, schedule_1]
          else
            [List.first(schedules_reversed)]
          end

        _ ->
          [struct(Schedule, departure_time: now)]
      end

    schedules
    |> Enum.reject(&is_nil/1)
    |> Enum.sort_by(& &1.departure_time)
  end
end
