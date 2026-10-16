defmodule Screens.V2.CandidateGenerator.Widgets.RealtimeDepartures do
  @moduledoc """
  Candidate generator for LCD RDS Items
  Takes in the generated sections from Screens.V2.CandidateGenerator.Widgets.RdsDepartures and
  handles the roll-up and creation of the actual widget that will be serialized and used on
  the screen itself.
  """

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

  alias Screens.V2.WidgetInstance.Departures.NormalSection.{
    AlertRow,
    HeadwayRow,
    SpecialTripRow
  }

  alias Screens.V2.WidgetInstance.DeparturesNoData
  alias ScreensConfig.{Departures, FreeTextLine, Screen}
  alias ScreensConfig.Departures.{Filters, Section}
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
         departures,
         slot_names,
         order,
         screen,
         now
       ) do
    sections_config_to_departure_sections_map =
      departures
      |> @rds.get(now)
      |> RdsDepartures.create_departure_sections(departures, screen, &post_process_rows/3)

    [
      create_departures_instance(
        sections_config_to_departure_sections_map,
        screen,
        slot_names,
        order,
        now
      )
    ]
  end

  @spec create_departures_instance(
          [{Section.t(), DeparturesWidget.section()}],
          Screen.t(),
          [atom()],
          non_neg_integer(),
          DateTime.t()
        ) :: widget()
  defp create_departures_instance(
         config_to_departures_map,
         screen,
         slot_names,
         order,
         now
       ) do
    if Enum.all?(config_to_departures_map, fn {_, departure_section} ->
         match?(%NoDataSection{}, departure_section)
       end) do
      %DeparturesNoData{screen: screen, show_alternatives?: true}
    else
      %DeparturesWidget{
        screen: screen,
        sections:
          config_to_departures_map
          |> Enum.map(fn
            {_section, %OvernightSection{} = overnight_section} ->
              overnight_section

            {_section, %NoServiceSection{} = no_service_section} ->
              no_service_section

            # The current headway section presentation is just one row with a headway value,
            # so we can reuse a NormalSection with a single Headway row
            {
              %Section{header: header, layout: layout, grouping_type: grouping_type},
              %HeadwaySection{
                headsign: headsign,
                route: route,
                time_range: time_range
              }
            } ->
              %NormalSection{
                header: header,
                layout: layout,
                grouping_type: grouping_type,
                rows: [
                  %HeadwayRow{
                    displayed_headsign: headsign,
                    route: route,
                    range: time_range,
                    direction_id: nil
                  }
                ]
              }

            {_section, %NormalSection{} = normal_section} ->
              normal_section

            {section, no_data_section} ->
              no_data_section(section, no_data_section)
          end),
        slot_names: slot_names,
        order: order,
        now: now
      }
    end
  end

  defp no_data_section(
         %Section{header: header, layout: layout, grouping_type: grouping_type},
         %NoDataSection{mode: mode}
       ) do
    %NormalSection{
      rows: [
        %FreeTextLine{
          icon: Route.icon_from_mode(mode),
          text: ["No departures currently available"]
        }
      ],
      header: header,
      layout: layout,
      grouping_type: grouping_type
    }
  end

  defp post_process_rows(
         rows,
         %Section{filters: filters, bidirectional: bidirectional, grouping_type: grouping_type},
         _total_section_count
       ) do
    rows
    |> filter_rows(filters)
    |> maybe_sort_by_direction_id(grouping_type)
    |> RdsDepartures.maybe_make_bidirectional(bidirectional)
  end

  defp filter_rows(rows, %Filters{route_directions: route_directions}) do
    rows |> filter_by_route_direction(route_directions)
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

  defp route_direction(%SpecialTripRow{
         schedule: %Schedule{route: %Route{id: id}, direction_id: direction_id}
       }) do
    %RouteDirection{route_id: id, direction_id: direction_id}
  end

  defp route_direction(%HeadwayRow{route: %Route{id: id}, direction_id: direction_id}) do
    %RouteDirection{route_id: id, direction_id: direction_id}
  end

  defp route_direction(%AlertRow{route: route, direction_id: direction_id}) do
    %RouteDirection{route_id: route.id, direction_id: direction_id}
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
