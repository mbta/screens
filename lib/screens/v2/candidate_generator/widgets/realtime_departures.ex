defmodule Screens.V2.CandidateGenerator.Widgets.RealtimeDepartures do
  @moduledoc """
  Candidate generator for LCD RDS Items
  Takes in the generated sections from Screens.V2.CandidateGenerator.Widgets.RdsDepartures and
  handles the roll-up and creation of the actual widget that will be serialized and used on
  the screen itself. 
  """

  alias Screens.Routes.Route
  alias Screens.Schedules.Schedule
  alias Screens.Trips.Trip
  alias Screens.V2.CandidateGenerator.Widgets.RdsDepartures
  alias Screens.V2.Departure
  alias Screens.V2.RDS
  alias Screens.V2.WidgetInstance.Departures, as: DeparturesWidget

  alias Screens.V2.WidgetInstance.Departures.{
    HeadwaySection,
    NoDataSection,
    NormalSection,
    NoServiceSection,
    OvernightSection
  }

  alias Screens.V2.WidgetInstance.DeparturesNoData
  alias ScreensConfig.{Departures, FreeTextLine, Screen}
  alias ScreensConfig.Departures.{Filters, Query, Section}
  alias ScreensConfig.Departures.Filters.{RouteDirections, RouteDirections.RouteDirection}
  alias ScreensConfig.Screen.{Busway, PreFare}

  import Screens.Inject
  @rds injected(RDS)

  @type widget :: DeparturesNoData.t() | DeparturesWidget.t()

  @spec departures_instances(Screen.t(), DateTime.t()) :: [widget()]
  def departures_instances(%Screen{app_params: app_params} = screen, now) do
    app_params
    |> departures_slots()
    |> Enum.with_index()
    |> Enum.flat_map(fn {{departures, slots}, index} ->
      generate_instances(departures, slots, index, screen, now)
    end)
  end

  @spec generate_instances(Departures.t(), [atom()], non_neg_integer(), Screen.t(), DateTime.t()) ::
          [widget()]
  defp generate_instances(departures, _slot_names, _order, _screen, _now)
       when is_nil(departures) or departures.sections == [],
       do: []

  defp generate_instances(
         %Departures{sections: sections} = departures,
         slot_names,
         order,
         screen,
         now
       ) do
    sections_data =
      departures
      |> @rds.get(now)
      |> RdsDepartures.create_departure_sections(departures, &post_process_rows/4, now)
      |> IO.inspect()

    [create_departures_instance(sections_data, sections, screen, slot_names, order, now)]
  end

  @spec create_departures_instance(
          [DeparturesWidget.section()],
          Section.t(),
          Screen.t(),
          [atom()],
          non_neg_integer(),
          DateTime.t()
        ) :: widget()
  defp create_departures_instance(
         sections_data,
         sections,
         screen,
         slot_names,
         order,
         now
       ) do
    sections_data_with_sections_config = Enum.zip(sections_data, sections)

    # As we begin to support other rows/sections/widgets, add them in here
    if has_valid_normal_section?(sections_data_with_sections_config) do
      %DeparturesWidget{
        screen: screen,
        sections:
          sections_data_with_sections_config
          |> Enum.map(fn
            {%NormalSection{rows: rows} = normal_section, _section} ->
              %{
                normal_section
                | rows:
                    Enum.map(rows, fn
                      %Departure{} = departure -> departure
                      # Treat First Trips as Countdowns while we don't support them yet
                      {%Schedule{} = schedule, :first_trip} -> %Departure{schedule: schedule}
                    end)
              }

            {unsupported_section, section} ->
              handle_unsupported_sections(unsupported_section, section)
          end),
        slot_names: slot_names,
        order: order,
        now: now
      }
    else
      %DeparturesNoData{screen: screen, show_alternatives?: true}
    end
  end

  defp has_valid_normal_section?(sections_data) do
    Enum.any?(sections_data, fn {section_data, %Section{header_only: header_only}} ->
      header_only ||
        (is_struct(section_data, NormalSection) && has_valid_normal_section_row?(section_data))
    end)
  end

  defp has_valid_normal_section_row?(%NormalSection{rows: rows}) do
    Enum.any?(rows, fn row ->
      is_struct(row, Departure) || match?({%Schedule{}, :first_trip}, row)
    end)
  end

  defp handle_unsupported_sections(
         section_to_change,
         %Section{
           header: header,
           layout: layout,
           grouping_type: grouping_type,
           query: %Query{params: %Query.Params{direction_id: direction_id}}
         }
       ) do
    text =
      case section_to_change do
        %HeadwaySection{route: route, headsign: headsign} ->
          headway_text(route, headsign)

        %NoDataSection{route: route} ->
          no_data_text(route, direction_id)

        %OvernightSection{routes: routes} ->
          no_data_text(List.first(routes), direction_id)

        %NoServiceSection{routes: routes} ->
          no_data_text(List.first(routes), direction_id)
      end

    %NormalSection{
      rows: [text],
      header: header,
      layout: layout,
      grouping_type: grouping_type
    }
  end

  defp post_process_rows(
         rows,
         %Section{filters: filters, bidirectional: bidirectional, grouping_type: grouping_type},
         _total_section_count,
         now
       ) do
    rows
    |> filter_rows(filters, now)
    |> maybe_sort_by_direction_id(grouping_type)
    |> RdsDepartures.maybe_make_bidirectional(bidirectional)
  end

  defp headway_text(route, headsign) do
    %FreeTextLine{
      icon: if(route, do: Route.icon(route), else: nil),
      text: [no_departures_message(headsign)]
    }
  end

  @spec no_data_text(Route.t() | nil, Trip.direction() | :both) :: FreeTextLine.t()
  defp no_data_text(nil, _direction_id) do
    %FreeTextLine{
      icon: nil,
      text: [no_departures_message()]
    }
  end

  defp no_data_text(route, direction_id) when direction_id == :both do
    %FreeTextLine{
      icon: Route.icon(route),
      text: [no_departures_message()]
    }
  end

  # In cases where we have NoDataSections, we might have a partial route just for the icon
  # Omit the normalized direction name in this instance
  defp no_data_text(%Route{direction_names: nil} = route, _direction_id) do
    %FreeTextLine{
      icon: Route.icon(route),
      text: [no_departures_message()]
    }
  end

  defp no_data_text(route, direction_id) do
    %FreeTextLine{
      icon: Route.icon(route),
      text: [
        route
        |> Route.normalized_direction_names()
        |> Enum.at(direction_id, "")
        |> no_departures_message()
      ]
    }
  end

  defp no_departures_message, do: "No departures currently available"
  defp no_departures_message(name), do: "No #{name} departures available"

  defp filter_rows(
         rows,
         %Filters{max_minutes: max_minutes, route_directions: route_directions},
         now
       ) do
    rows
    |> filter_unsupported_rows()
    |> filter_by_time(max_minutes, now)
    |> filter_by_route_direction(route_directions)
  end

  defp filter_unsupported_rows(rows) do
    Enum.filter(rows, fn
      %Departure{} -> true
      {%Schedule{}, :first_trip} -> true
      _ -> false
    end)
  end

  @spec filter_by_time([NormalSection.row()], non_neg_integer() | nil, DateTime.t()) :: [
          NormalSection.row()
        ]
  defp filter_by_time(rows, nil, _now), do: rows

  defp filter_by_time(rows, max_minutes, now) do
    latest_time = DateTime.add(now, max_minutes, :minute)

    Enum.filter(rows, fn
      %Departure{} = departure ->
        DateTime.compare(Departure.time(departure), latest_time) != :gt

      {%Schedule{} = schedule, :first_trip} ->
        DateTime.compare(Schedule.time(schedule), latest_time) != :gt
    end)
  end

  @spec filter_by_route_direction([NormalSection.row()], RouteDirections.t() | nil) :: [
          NormalSection.row()
        ]
  defp filter_by_route_direction(rows, %RouteDirections{
         action: :include,
         targets: targets
       }) do
    Enum.filter(rows, &row_in_route_directions?(&1, targets))
  end

  defp filter_by_route_direction(rows, %RouteDirections{
         action: :exclude,
         targets: targets
       }) do
    Enum.reject(rows, &row_in_route_directions?(&1, targets))
  end

  defp filter_by_route_direction(departures, nil) do
    departures
  end

  defp row_in_route_directions?(row, route_directions) do
    route_direction(row) in route_directions
  end

  defp route_direction(%Departure{} = d) do
    %RouteDirection{route_id: Departure.route(d).id, direction_id: Departure.direction_id(d)}
  end

  defp route_direction(
         {%Schedule{route: %Route{id: id}, direction_id: direction_id}, :first_trip}
       ) do
    %RouteDirection{route_id: id, direction_id: direction_id}
  end

  defp maybe_sort_by_direction_id(departures, :destination),
    do: Enum.sort_by(departures, &(1 - RdsDepartures.departure_direction_id(&1)))

  defp maybe_sort_by_direction_id(departures, _grouping_type), do: departures

  defp departures_slots(%Busway{departures: d1, secondary_departures: d2}),
    do: [{d1, [:main_content, :main_content_left]}, {d2, [:main_content_right]}]

  defp departures_slots(%PreFare{departures: d, template: :duo}), do: [{d, [:main_content_left]}]
  defp departures_slots(%PreFare{departures: d, template: :solo}), do: [{d, [:large]}]
  defp departures_slots(%_app{departures: d}), do: [{d, [:main_content]}]
end
