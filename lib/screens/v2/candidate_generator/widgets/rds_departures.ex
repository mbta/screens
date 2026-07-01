defmodule Screens.V2.CandidateGenerator.Widgets.RdsDepartures do
  @moduledoc false

  alias Screens.Routes.Route
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

  alias Screens.V2.WidgetInstance.{DeparturesNoData, DeparturesNoService, OvernightDepartures}
  alias ScreensConfig.Departures

  alias ScreensConfig.Departures.{Header, Layout, Section}

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

  @spec map_to_departure_section(RDS.data(), boolean(), integer(), ([NormalSection.row()],
                                                                    Section.t(),
                                                                    number() ->
                                                                      [NormalSection.row()])) ::
          DeparturesWidget.section()

  defp map_to_departure_section(:error, _, _, _), do: %NoDataSection{}

  defp map_to_departure_section({:ok, []}, _, _, _), do: %NoDataSection{}

  defp map_to_departure_section(
         {:ok, items},
         section,
         section_count,
         post_process_rows_fn
       ) do
    case items do
      [%NoService{routes: routes}] ->
        %NoServiceSection{routes: routes}

      [%ServiceEnded{routes: routes}] ->
        %OvernightSection{routes: routes}

      [
        %Headways{
          routes: [%Route{id: route_id} | _rest],
          range: range,
          displayed_headsign: displayed_headsign
        }
      ] ->
        %HeadwaySection{route_id: route_id, time_range: range, headsign: displayed_headsign}

      _ ->
        %NormalSection{
          rows: create_and_sort_rows(items) |> post_process_rows_fn.(section, section_count),
          layout: %Layout{},
          header: %Header{}
        }
    end
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

  defp departure_direction_id(%Departure{} = departure), do: Departure.direction_id(departure)
  defp departure_direction_id({%Schedule{direction_id: direction_id}, _type}), do: direction_id
  defp departure_direction_id({_line, direction_id, _range, _headsign}), do: direction_id
end
