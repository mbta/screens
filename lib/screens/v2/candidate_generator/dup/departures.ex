defmodule Screens.V2.CandidateGenerator.Dup.Departures do
  @moduledoc false

  alias Screens.Alerts.Alert
  alias Screens.Config.Screen
  alias Screens.Config.V2.Departures
  alias Screens.Config.V2.Departures.{Headway, Query, Section}
  alias Screens.Config.V2.Departures.Query.Params
  alias Screens.Config.V2.Dup
  alias Screens.SignsUiConfig
  alias Screens.Stops.Stop
  alias Screens.Util
  alias Screens.V2.CandidateGenerator.Widgets
  alias Screens.V2.WidgetInstance.Departures, as: DeparturesWidget
  alias Screens.V2.WidgetInstance.DeparturesNoData

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
        create_station_with_routes_map_fn \\ &Stop.create_station_with_routes_map/1
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
        now
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
        now
      )

    primary_departures_instances ++ secondary_departures_instances
  end

  defp sections_data_to_departure_instances(sections_data, config, slot_ids, now) do
    sections =
      Enum.map(
        sections_data,
        &get_departure_instance_for_section(&1, length(sections_data) == 1, now)
      )

    Enum.map(slot_ids, fn slot_id ->
      if Enum.all?(sections, &(&1.type == :no_data_section)) do
        %DeparturesNoData{
          screen: config,
          slot_name: slot_id
        }
      else
        %DeparturesWidget{
          screen: config,
          section_data: sections,
          slot_names: [slot_id]
        }
      end
    end)
  end

  defp get_departure_instance_for_section(%{type: :no_data_section} = section, _, _), do: section

  defp get_departure_instance_for_section(
         %{
           departures: departures,
           alert: alert,
           headway: headway,
           stop_ids: stop_ids,
           route: route
         },
         is_only_section,
         now
       ) do
    visible_departures =
      if is_only_section do
        Enum.take(departures, 4)
      else
        Enum.take(departures, 2)
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
        if visible_departures == [] do
          %{type: :no_data_section, route: route}
        else
          %{type: :normal_section, rows: visible_departures}
        end
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
                                params: %Params{stop_ids: stop_ids, route_ids: route_ids} = params
                              },
                              headway: headway
                            } = section ->
      route =
        get_primary_route_for_section(stop_ids, route_ids, create_station_with_routes_map_fn)

      # If we know the predictions are unreliable, don't even bother fetching them.
      if not is_nil(route) and Screens.Config.State.mode_disabled?(route.type) do
        %{type: :no_data_section, route: route}
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
          route: route
        }
      end
    end)
    |> Enum.map(fn {:ok, data} -> data end)
  end

  # Alert will only have a value for sections that are configured for a station's ID
  defp get_section_route_from_alert(["place-" <> _ = stop_id], %Alert{
         informed_entities: informed_entities
       }) do
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

  # DUP sections will always show one mode.
  # For subway, each route will have its own section.
  # If the stop is served by two different subway/light rail routes, route_ids must be populated for each section
  # Otherwise, we only need the first route in the list of routes serving the stop.
  defp get_primary_route_for_section([stop_id | _], route_ids, create_station_with_routes_map_fn) do
    all_routes = create_station_with_routes_map_fn.(stop_id)

    if route_ids != [] do
      Enum.find(all_routes, fn route -> route.id in route_ids end)
    else
      List.first(all_routes)
    end
  end
end
