defmodule Screens.V2.CandidateGenerator.Widgets.RealtimeDepartures do
  @moduledoc false

  alias Screens.Config.Cache
  alias Screens.Routes.Route
  alias Screens.Schedules.Schedule
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
  @cache injected(Cache)

  @type widget :: DeparturesNoData.t() | DeparturesWidget.t()

  @spec departures_instances(Screen.t(), DateTime.t()) :: [widget()]
  def departures_instances(%Screen{app_params: app_params} = screen, now) do
    if screen_devops_mode(screen) in @cache.disabled_modes() do
      [%DeparturesNoData{screen: screen, show_alternatives?: false}]
    else
      app_params
      |> departures_slots()
      |> Enum.with_index()
      |> Enum.flat_map(fn {{departures, slots}, index} ->
        generate_instances(departures, slots, index, screen, now)
      end)
    end
  end

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

    [create_departures_instance(sections_data, sections, screen, slot_names, order, now)]
  end

  defp create_departures_instance(
         sections_data,
         sections,
         screen,
         slot_names,
         order,
         now
       ) do
    sections_data_with_sections_config = Enum.zip(sections_data, sections)

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

  defp filter_by_time(departures, nil, _now), do: departures

  defp filter_by_time(departures, max_minutes, now) do
    latest_time = DateTime.add(now, max_minutes, :minute)

    Enum.filter(departures, fn departure ->
      DateTime.compare(Departure.time(departure), latest_time) != :gt
    end)
  end

  defp filter_by_route_direction(departures, %RouteDirections{
         action: :include,
         targets: targets
       }) do
    Enum.filter(departures, &departure_in_route_directions?(&1, targets))
  end

  defp filter_by_route_direction(departures, %RouteDirections{
         action: :exclude,
         targets: targets
       }) do
    Enum.reject(departures, &departure_in_route_directions?(&1, targets))
  end

  defp filter_by_route_direction(departures, nil) do
    departures
  end

  defp departure_in_route_directions?(d, route_directions) do
    route_direction(d) in route_directions
  end

  defp route_direction(d) do
    %RouteDirection{route_id: Departure.route(d).id, direction_id: Departure.direction_id(d)}
  end

  defp maybe_sort_by_direction_id(departures, :destination),
    do: Enum.sort_by(departures, &(1 - RdsDepartures.departure_direction_id(&1)))

  defp maybe_sort_by_direction_id(departures, _grouping_type), do: departures

  defp departures_slots(%Busway{departures: d1, secondary_departures: d2}),
    do: [{d1, [:main_content, :main_content_left]}, {d2, [:main_content_right]}]

  defp departures_slots(%PreFare{departures: d, template: :duo}), do: [{d, [:main_content_left]}]
  defp departures_slots(%PreFare{departures: d, template: :solo}), do: [{d, [:large]}]
  defp departures_slots(%_app{departures: d}), do: [{d, [:main_content]}]

  # Some screen types are always configured to show departures for one specific transit mode. In
  # that case, if the mode is devops-disabled, we immediately know the whole screen should display
  # a "no data" message. Right now, we only handle Bus Shelters
  defp screen_devops_mode(%Screen{app_id: :bus_shelter_v2}), do: :bus
  defp screen_devops_mode(_), do: nil
end
