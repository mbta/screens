defmodule Screens.V2.CandidateGenerator.Widgets.RdsDepartures do
  @moduledoc """
  Candidate Generator for RDS Items. 
  Takes in RDS items and generates Screens.V2.WidgetInstance.Departures sections
  to eventually be serialized and used as a part of the Departures Widget.

  Note: This candidate generator only creates sections, and does not do the roll-up
  of full screen presentations

  """

  alias Screens.Schedules.Schedule
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

  alias Screens.V2.WidgetInstance.DeparturesNoData
  alias ScreensConfig.Departures
  alias ScreensConfig.Departures.Section

  @type post_process_rows_fn_t ::
          ([NormalSection.row()], Section.t(), non_neg_integer(), DateTime.t() ->
             [NormalSection.row()])
  @type widget :: DeparturesNoData.t() | DeparturesWidget.t()

  @spec create_departure_sections(
          [RDS.item()],
          Departures.t(),
          post_process_rows_fn_t(),
          DateTime.t()
        ) :: [DeparturesWidget.section()]
  def create_departure_sections(
        rds_sections,
        %Departures{sections: departure_sections},
        post_process_rows_fn \\ fn rows, _section, _total_section_count, _now -> rows end,
        now
      ) do
    total_section_count = length(rds_sections)

    Enum.zip(rds_sections, departure_sections)
    |> Enum.map(fn {rds_section, section} ->
      map_to_departure_section(
        rds_section,
        section,
        total_section_count,
        post_process_rows_fn,
        now
      )
    end)
  end

  @spec map_to_departure_section(
          RDS.data(),
          Section.t(),
          non_neg_integer(),
          post_process_rows_fn_t(),
          DateTime.t()
        ) ::
          DeparturesWidget.section()

  defp map_to_departure_section(:error, _, _, _, _), do: %NoDataSection{}

  # header_only sections are only supported on LCD screens
  defp map_to_departure_section(
         _,
         %Section{
           header_only: true,
           header: header,
           layout: layout,
           grouping_type: grouping_type
         },
         _,
         _,
         _
       ),
       do: %NormalSection{
         rows: [],
         header: header,
         layout: layout,
         grouping_type: grouping_type
       }

  defp map_to_departure_section({:ok, []}, _, _, _, _), do: %NoDataSection{}

  defp map_to_departure_section(
         {:ok, items},
         %Section{header: header, layout: layout, grouping_type: grouping_type} = section,
         section_count,
         post_process_rows_fn,
         now
       ) do
    case items do
      [%NoService{routes: routes}] ->
        %NoServiceSection{routes: routes}

      [
        %ServiceEnded{displayed_headsign: displayed_headsign, routes: routes}
      ] ->
        %OvernightSection{headsign: displayed_headsign, header: header, routes: routes}

      [
        %Headways{
          routes: [first_route | _rest],
          range: range,
          displayed_headsign: displayed_headsign
        }
      ] ->
        %HeadwaySection{route: first_route, time_range: range, headsign: displayed_headsign}

      _ ->
        %NormalSection{
          rows:
            items |> create_and_sort_rows() |> post_process_rows_fn.(section, section_count, now),
          layout: layout,
          header: header,
          grouping_type: grouping_type
        }
    end
  end

  @spec create_and_sort_rows([RDS.item()]) :: [NormalSection.row()]
  defp create_and_sort_rows(rds_items) do
    grouped_items =
      Enum.group_by(rds_items, fn
        %ServiceEnded{} -> :service_ended
        %Headways{} -> :headways
        _ -> :other
      end)

    service_ended_items = Map.get(grouped_items, :service_ended, [])
    headway_items = Map.get(grouped_items, :headways, [])
    other_items = Map.get(grouped_items, :other, [])

    sorted_departures_from_rds(other_items) ++
      headways_from_rds(headway_items) ++
      sorted_departures_from_rds(service_ended_items, true)
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

  @spec sorted_departures_from_rds([RDS.item()], boolean()) :: [Departure.t()]
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

  @spec headways_from_rds([RDS.Headways.t()]) :: [NormalSection.headway_row()]
  defp headways_from_rds(headway_states) do
    Enum.flat_map(headway_states, fn
      %Headways{
        destinations: [{_stop, line, _headsign} | _],
        direction_id: direction_id,
        range: range,
        displayed_headsign: displayed_headsign
      } ->
        [{line, direction_id, range, displayed_headsign}]
    end)
  end

  @spec departure_rows_from_state(RDS.item()) ::
          [Departure.t()] | [NormalSection.special_trip()]
  defp departure_rows_from_state(%Countdowns{departures: departures}), do: departures

  defp departure_rows_from_state(%FirstTrip{first_schedule: first_schedule}) do
    [{first_schedule, :first_trip}]
  end

  defp departure_rows_from_state(%ServiceEnded{last_schedule: last_schedule}) do
    [{last_schedule, :service_ended}]
  end

  defp departure_rows_from_state(%NoService{}), do: []

  @spec departure_time(Departure.t() | NormalSection.special_trip()) :: DateTime.t()
  defp departure_time(%Departure{} = departure), do: Departure.time(departure)
  defp departure_time({%Schedule{} = schedule, _type}), do: Schedule.time(schedule)

  def departure_direction_id(%Departure{} = departure), do: Departure.direction_id(departure)
  def departure_direction_id({%Schedule{direction_id: direction_id}, _type}), do: direction_id
  def departure_direction_id({_line, direction_id, _range, _headsign}), do: direction_id
end
