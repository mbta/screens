defmodule Screens.V2.CandidateGenerator.Widgets.RdsDepartures do
  @moduledoc false

  alias Screens.Lines.Line
  alias Screens.Routes.Route
  alias Screens.Schedules.Schedule
  alias Screens.Trips.Trip
  alias Screens.V2.Departure
  alias Screens.V2.RDS
  alias Screens.V2.RDS.{Countdowns, FirstTrip, Headways, NoService, ServiceEnded}
  alias Screens.V2.WidgetInstance.Departures, as: DeparturesWidget

  alias Screens.V2.WidgetInstance.Departures.{
    HeadwaySection,
    NoDataSection,
    NormalSection,
    NoServiceSection,
    OvernightSection
  }

  alias Screens.V2.WidgetInstance.{DeparturesNoData, DeparturesNoService, OvernightDepartures}
  alias ScreensConfig.Departures
  alias ScreensConfig.Departures.Section

  @type widget :: DeparturesNoData.t() | DeparturesWidget.t()

  def create_departure_sections(
        rds_sections,
        %Departures{sections: departure_sections},
        post_process_rows_fn \\ fn rows, _section, _total_section_count -> rows end
      ) do
    total_section_count = length(rds_sections)

    Enum.zip(rds_sections, departure_sections)
    |> Enum.map(fn {rds_section, section} ->
      map_to_departure_section(
        rds_section,
        section,
        total_section_count,
        post_process_rows_fn
      )
    end)
  end

  @spec map_to_departure_section(RDS.section_t(), Section.t(), number(), ([Departure.t()] ->
                                                                            [Departure.t()])) ::
          DeparturesWidget.section()

  defp map_to_departure_section(:error, _, _, _), do: %NoDataSection{}

  defp map_to_departure_section({:ok, []}, _, _, _), do: %NoDataSection{}

  defp(
    map_to_departure_section(
      {:ok, rds_list},
      %Section{header: header, layout: layout, grouping_type: grouping_type} = section,
      total_section_count,
      post_process_rows_fn
    )
  ) do
    cond do
      no_service?(rds_list) ->
        %NoServiceSection{
          routes:
            rds_list
            |> Enum.flat_map(fn %RDS{state: %NoService{routes: routes}} -> routes end)
            |> Enum.uniq()
        }

      service_ended?(rds_list) ->
        %OvernightSection{
          routes:
            rds_list
            |> Enum.map(fn %RDS{state: %ServiceEnded{last_schedule: %Schedule{route: route}}} ->
              route
            end)
            |> Enum.uniq()
        }

      headways?(rds_list) ->
        create_headway_section(rds_list)

      true ->
        rows =
          rds_list
          |> create_and_sort_rows()
          |> post_process_rows_fn.(section, total_section_count)

        %NormalSection{
          rows: rows,
          layout: layout,
          header: header,
          grouping_type: grouping_type
        }
    end
  end

  defp no_service?(rds_list) do
    Enum.all?(rds_list, &is_struct(&1.state, NoService))
  end

  defp service_ended?(rds_list) do
    Enum.all?(rds_list, &is_struct(&1.state, ServiceEnded))
  end

  defp headways?(rds_list) do
    Enum.all?(rds_list, &is_struct(&1.state, Headways))
  end

  @spec create_headway_section([RDS.t()]) :: HeadwaySection.t()
  # Bidirectional -> Use no headsign for the trains message
  defp create_headway_section([
         %RDS{state: %{route_id: route_id, direction_id: direction_id_one, range: range}}
         | [%RDS{state: %{route_id: route_id, direction_id: direction_id_two, range: range}}]
       ])
       when direction_id_one != direction_id_two do
    %HeadwaySection{
      route: route_id,
      time_range: range,
      headsign: nil
    }
  end

  # Use the headsign if the destinations have the same headsign,
  # use the direction name if they have the same direction name,
  # otherwise default to no headsign
  defp create_headway_section(
         [
           %RDS{
             headsign: headsign,
             line: %Line{id: first_line_id},
             state: %Headways{
               route_id: route_id,
               direction_name: direction_name,
               direction_id: direction_id,
               range: range
             }
           }
           | _
         ] = destinations
       ) do
    %HeadwaySection{
      route: route_id,
      time_range: range,
      headsign:
        cond do
          Enum.all?(destinations, fn %RDS{headsign: other_headsign} ->
            headsign == other_headsign
          end) ->
            headsign

          Enum.all?(
            destinations,
            fn %RDS{
                 line: %Line{id: other_line_id},
                 state: %Headways{direction_id: other_direction_id}
               } ->
              first_line_id == other_line_id and direction_id == other_direction_id
            end
          ) ->
            direction_name

          true ->
            nil
        end
    }
  end

  def build_instances(
        slot_names,
        _departure_sections,
        true = _all_section_no_data,
        _all_section_service_ended,
        config,
        _now
      ) do
    Enum.map(slot_names, &%DeparturesNoData{screen: config, slot_name: &1})
  end

  def build_instances(
        slot_names,
        _departure_sections,
        _all_section_no_data,
        true = _all_section_service_ended,
        config,
        _now
      ) do
    Enum.map(slot_names, &%OvernightDepartures{screen: config, slot_names: [&1]})
  end

  def build_instances(
        slot_names,
        departure_sections,
        _all_section_no_data,
        _all_section_service_ended,
        config,
        now
      ) do
    cond do
      Enum.all?(departure_sections, &is_struct(&1, NoServiceSection)) ->
        Enum.map(
          slot_names,
          &%DeparturesNoService{
            screen: config,
            slot_name: &1,
            routes:
              departure_sections
              |> Enum.flat_map(fn %NoServiceSection{routes: routes} -> routes end)
              |> Enum.map(fn route -> Route.icon(route) end)
              |> Enum.uniq()
          }
        )

      Enum.all?(departure_sections, &is_struct(&1, OvernightSection)) ->
        Enum.map(
          slot_names,
          &%OvernightDepartures{
            screen: config,
            slot_names: [&1],
            routes:
              departure_sections
              |> Enum.flat_map(fn %OvernightSection{routes: routes} -> routes end)
              |> Enum.map(fn route -> Route.icon(route) end)
              |> Enum.uniq()
          }
        )

      true ->
        Enum.map(
          slot_names,
          &sections_to_departure_widget(&1, departure_sections, config, now)
        )
    end
  end

  defp sections_to_departure_widget(slot_name, departure_sections, config, now) do
    %DeparturesWidget{
      screen: config,
      sections: departure_sections,
      slot_names: [slot_name],
      now: now
    }
  end

  @spec create_and_sort_rows([RDS.t()]) :: [NormalSection.row()]
  defp create_and_sort_rows(rds_list) do
    grouped_rds =
      Enum.group_by(rds_list, fn
        %RDS{state: %ServiceEnded{}} -> :service_ended
        %RDS{state: %Headways{}} -> :headways
        _ -> :other
      end)

    service_ended_rds = Map.get(grouped_rds, :service_ended, [])
    headway_rds = Map.get(grouped_rds, :headways, [])
    rds = Map.get(grouped_rds, :other, [])

    sorted_departures_from_rds(rds) ++
      headways_from_rds(rds ++ service_ended_rds, headway_rds) ++
      sorted_departures_from_rds(service_ended_rds, true)
  end

  # "Bidirectional" mode: take only the first departure, and the next departure in the opposite
  # direction from the first, if one exists.
  @spec maybe_make_bidirectional([Departure.t()], boolean()) :: [Departure.t()]
  def maybe_make_bidirectional([], _), do: []
  def maybe_make_bidirectional(departures, false), do: departures

  def maybe_make_bidirectional([first | rest], true) do
    first_direction = departure_direction_id(first)

    opposite? =
      Enum.find(rest, Enum.at(rest, 0), &(departure_direction_id(&1) == 1 - first_direction))

    Enum.reject([first, opposite?], &is_nil/1)
  end

  @spec sorted_departures_from_rds([RDS.t()], boolean()) :: [Departure.t()]
  defp sorted_departures_from_rds(rds, reverse \\ false) do
    sort_order =
      if reverse do
        :desc
      else
        :asc
      end

    rds
    |> Enum.flat_map(&departure_rows_from_state(&1))
    |> Enum.sort_by(
      &departure_time(&1),
      {
        sort_order,
        DateTime
      }
    )
  end

  @spec headways_from_rds([RDS.t()], [RDS.t()]) :: [NormalSection.headway_row()]
  defp headways_from_rds(
         rds,
         headway_rds
       ) do
    # If there are other similar line/direction_id destinations that are in one of the other states,
    # disregard the headway for that particular destination
    lines_in_other_states =
      rds
      |> Enum.flat_map(&extract_line_direction_pairs/1)
      |> MapSet.new()

    headway_rds
    |> Enum.reject(fn %RDS{
                        line: %Line{id: line_id},
                        state: %Headways{direction_id: direction_id}
                      } ->
      MapSet.member?(lines_in_other_states, {line_id, direction_id})
    end)
    |> Enum.group_by(fn %RDS{
                          line: line,
                          state: %Headways{direction_id: direction_id}
                        } ->
      {line, direction_id}
    end)
    |> Enum.flat_map(fn {{line, direction_id}, rds_list} ->
      %RDS{headsign: headsign, state: %Headways{direction_name: direction_name, range: range}} =
        hd(rds_list)

      # If there are multiple headways with the same line but different headsigns,
      # combine them and use the direction name
      displayed_headsign = if length(rds_list) == 1, do: headsign, else: direction_name

      [{line, direction_id, range, displayed_headsign}]
    end)
  end

  @spec departure_rows_from_state(RDS.t()) ::
          [Departure.t()] | [NormalSection.special_trip()]
  defp departure_rows_from_state(%RDS{state: %Countdowns{departures: departures}}), do: departures

  defp departure_rows_from_state(%RDS{state: %FirstTrip{first_schedule: first_schedule}}) do
    [{first_schedule, :first_trip}]
  end

  defp departure_rows_from_state(%RDS{state: %ServiceEnded{last_schedule: last_schedule}}) do
    [{last_schedule, :service_ended}]
  end

  defp departure_rows_from_state(%RDS{state: %NoService{}}), do: []

  @spec departure_time(Departure.t() | NormalSection.special_trip()) :: DateTime.t()
  defp departure_time(%Departure{} = departure), do: Departure.time(departure)
  defp departure_time({%Schedule{} = schedule, _type}), do: Schedule.time(schedule)

  defp departure_direction_id(%Departure{} = departure), do: Departure.direction_id(departure)
  defp departure_direction_id({%Schedule{direction_id: direction_id}, _type}), do: direction_id
  defp departure_direction_id({_line, direction_id, _range, _headsign}), do: direction_id

  defp extract_line_direction_pairs(%RDS{line: %Line{id: line_id}, state: state}) do
    case state do
      %NoService{direction_id: nil} ->
        []

      %NoService{direction_id: direction_id} ->
        [{line_id, direction_id}]

      %Countdowns{departures: [departure | _]} ->
        [{line_id, Departure.direction_id(departure)}]

      %FirstTrip{first_schedule: %Schedule{trip: %Trip{direction_id: direction_id}}} ->
        [{line_id, direction_id}]

      %ServiceEnded{last_schedule: %Schedule{trip: %Trip{direction_id: direction_id}}} ->
        [{line_id, direction_id}]
    end
  end
end
