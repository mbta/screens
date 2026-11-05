defmodule Screens.V2.CandidateGenerator.Widgets.RdsDepartures do
  @moduledoc """
  Candidate Generator for RDS Items.
  Takes in RDS items and generates Screens.V2.WidgetInstance.Departures sections
  to eventually be serialized and used as a part of the Departures Widget.

  Note: This candidate generator only creates sections, and does not do the roll-up
  of full screen presentations

  """
  alias Screens.Alerts.Alert
  alias Screens.Schedules.Schedule
  alias Screens.V2.Departure
  alias Screens.V2.RDS
  alias Screens.V2.RDS.{Countdowns, FirstTrip, Headways, ImpactedByAlert, NoService, ServiceEnded}
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

  alias ScreensConfig.{Departures, Screen}
  alias ScreensConfig.Departures.{Header, Mode, Params, Section}

  # These screen types not display alerts within Departures because they already have Alert widgets
  # that should cover all alerts we would otherwise be showing in Departures
  @app_ids_without_departure_alerts [:bus_shelter_v2, :dup_v2]
  @type post_process_rows_fn_t :: ([NormalSection.row()], Section.t(), non_neg_integer() ->
                                     [NormalSection.row()])
  @type widget :: DeparturesNoData.t() | DeparturesWidget.t()

  @spec create_departure_sections(
          [RDS.data()],
          Departures.t(),
          Screen.t(),
          post_process_rows_fn_t()
        ) :: [{Section.t(), DeparturesWidget.section()}]
  def create_departure_sections(
        rds_data,
        %Departures{sections: sections},
        screen,
        post_process_rows_fn \\ fn rows, _section, _total_section_count -> rows end
      ) do
    processed_rds_and_section_data =
      rds_data
      |> filter_alerts_for_app_ids(screen)
      |> Enum.zip(sections)
      |> maybe_combine_alert_sections(screen)

    total_section_count = length(processed_rds_and_section_data)

    Enum.map(processed_rds_and_section_data, fn {rds_section, section} ->
      {
        section,
        map_to_departure_section(
          rds_section,
          section,
          total_section_count,
          post_process_rows_fn,
          screen
        )
      }
    end)
  end

  @spec filter_alerts_for_app_ids([RDS.data()], Screen.t()) :: [RDS.data()]
  defp filter_alerts_for_app_ids(rds_data, %Screen{app_id: app_id})
       when app_id in @app_ids_without_departure_alerts do
    Enum.map(rds_data, fn
      {:ok, rds_items} ->
        filtered = Enum.reject(rds_items, &match?(%RDS.ImpactedByAlert{}, &1))

        # Only use the filtered list if there are other items besides alerts to show
        if Enum.empty?(filtered) do
          {:ok, rds_items}
        else
          {:ok, filtered}
        end

      other ->
        other
    end)
  end

  defp filter_alerts_for_app_ids(rds_data, _screen), do: rds_data

  defp maybe_combine_alert_sections(rds_and_sections_data, %Screen{app_id: app_id})
       when app_id in @app_ids_without_departure_alerts, do: rds_and_sections_data

  defp maybe_combine_alert_sections(rds_and_section_data, _screen) do
    # If we have all of the states in one section be an alert, we'll try and combine with other sections
    # that are fully alerts and have similar modes
    combine_alert_sections(rds_and_section_data)
  end

  @spec combine_alert_sections([{RDS.data(), Section.t()}]) ::
          [{RDS.data(), Section.t()}]
  defp combine_alert_sections([
         {_section_states, %Section{params: %Params{mode: section_mode}}} = first | rest
       ]) do
    if valid_alert_section?(first) do
      rest
      |> slice_next_alert_section(section_mode)
      |> case do
        {nil, _sections} ->
          [first | combine_alert_sections(rest)]

        {section_to_consolidate, sliced_section_list} ->
          combine_alert_sections([
            consolidate_alert_sections(first, section_to_consolidate) | sliced_section_list
          ])
      end
    else
      [first | combine_alert_sections(rest)]
    end
  end

  defp combine_alert_sections([first | rest]) do
    [first | combine_alert_sections(rest)]
  end

  defp combine_alert_sections([]), do: []

  defp slice_next_alert_section(sections, mode_to_match) do
    alert_section_to_consolidate =
      Enum.find(sections, fn
        {_section_states, %Section{params: %Params{mode: section_mode}}} = section ->
          valid_alert_section?(section) and same_route_type?(section_mode, mode_to_match)

        _ ->
          false
      end)

    if is_nil(alert_section_to_consolidate) do
      {nil, sections}
    else
      {alert_section_to_consolidate, List.delete(sections, alert_section_to_consolidate)}
    end
  end

  defp consolidate_alert_sections(
         {{:ok, states},
          %Section{header: %Header{title: title}, params: %Params{mode: mode}} = section},
         {{:ok, states_to_add},
          %Section{
            header: %Header{title: title_to_consolidate},
            params: %Params{mode: mode_to_check}
          }}
       ) do
    # Check if we need to combine sections of different modes,
    # if so remove the `representative_route` in favor of a different icon
    alert_states = combine_alert_states(states, states_to_add, mode == mode_to_check)

    {{:ok, alert_states},
     if title == nil and title_to_consolidate == nil do
       section
     else
       section
       |> put_in([Access.key(:header), Access.key(:title)], mode_to_header_title(mode))
     end}
  end

  defp combine_alert_states(states, states_to_add, sections_have_same_mode?) do
    Enum.reduce(states_to_add, states, fn %ImpactedByAlert{alert: %Alert{id: alert_id}} =
                                            state_to_add,
                                          states ->
      states
      |> Enum.find_index(&(&1.alert.id == alert_id))
      |> case do
        nil ->
          states ++ state_to_add

        index ->
          List.update_at(states, index, fn state ->
            state
            |> update_in([Access.key(:destinations)], fn destinations ->
              (destinations ++ state_to_add.destinations) |> Enum.uniq()
            end)
            |> update_in([Access.key(:routes)], fn routes ->
              (routes ++ state_to_add.routes) |> Enum.uniq()
            end)
            |> put_in([Access.key(:displayed_headsign)], nil)
            |> put_in(
              [Access.key(:mode)],
              if sections_have_same_mode? do
                state.mode
              else
                nil
              end
            )
          end)
      end
    end)
  end

  defp valid_alert_section?(
         {_state, %Section{header: %Header{wayfinding_information: wayfinding_information}}}
       )
       when wayfinding_information != nil,
       do: false

  defp valid_alert_section?({{:ok, section_states}, _section}) do
    section_states != [] and Enum.all?(section_states, &match?(%ImpactedByAlert{}, &1))
  end

  defp valid_alert_section?(_), do: false

  @spec map_to_departure_section(
          RDS.data(),
          Section.t(),
          non_neg_integer(),
          post_process_rows_fn_t(),
          Screen.t()
        ) ::
          DeparturesWidget.section()

  # Header Only Section
  defp map_to_departure_section(
         _rds_section,
         %Section{
           header: header,
           layout: layout,
           grouping_type: grouping_type,
           params: nil
         },
         _section_count,
         _post_process_rows_fn,
         _screen
       ) do
    %NormalSection{
      rows: [],
      layout: layout,
      header: header,
      grouping_type: grouping_type,
      mode: nil
    }
  end

  defp map_to_departure_section(
         data,
         %Section{params: %Params{mode: mode}},
         _,
         _,
         _screen
       )
       when data == :error or data == {:ok, []},
       do: %NoDataSection{mode: mode}

  defp map_to_departure_section(
         {:ok, items},
         %Section{
           header: header,
           layout: layout,
           grouping_type: grouping_type,
           params: %Params{mode: mode} = params
         } =
           section,
         section_count,
         post_process_rows_fn,
         screen
       ) do
    case items do
      [
        %NoService{
          displayed_headsign: displayed_headsign,
          routes: routes
        }
      ] ->
        %NoServiceSection{
          headsign: displayed_headsign,
          header: header,
          routes: routes
        }

      [%ServiceEnded{displayed_headsign: displayed_headsign, routes: routes}] ->
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
        rows =
          items
          |> create_and_sort_rows(screen)
          |> post_process_rows_fn.(section, section_count)

        %NormalSection{
          rows: rows,
          layout: layout,
          header: header |> maybe_adjust_header_for_alerts(rows, mode),
          grouping_type: grouping_type,
          mode: get_in(params, [Access.key(:mode)])
        }
    end
  end

  @spec create_and_sort_rows([RDS.item()], Screen.t()) :: [NormalSection.row()]
  defp create_and_sort_rows(rds_items, screen) do
    grouped_items =
      Enum.group_by(rds_items, fn
        %ImpactedByAlert{} -> :alert
        %ServiceEnded{} -> :service_ended
        %Headways{} -> :headways
        _ -> :other
      end)

    alert_items = Map.get(grouped_items, :alert, [])
    service_ended_items = Map.get(grouped_items, :service_ended, [])
    headway_items = Map.get(grouped_items, :headways, [])
    other_items = Map.get(grouped_items, :other, [])

    alerts_from_rds(alert_items, screen) ++
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

  @spec alerts_from_rds([ImpactedByAlert.t()], Screen.t()) :: [NormalSection.row()]
  defp alerts_from_rds(_alert_states, %Screen{app_id: app_id})
       when app_id in @app_ids_without_departure_alerts do
    # Return empty list when all items are alerts, since we will show the alert separately
    []
  end

  defp alerts_from_rds(alert_states, _screen) do
    Enum.flat_map(alert_states, fn
      %ImpactedByAlert{
        alert: alert,
        destinations: [{home_stop, _line, _headsign} | _],
        direction_id: direction_id,
        displayed_headsign: displayed_headsign,
        location: location,
        mode: mode,
        routes: routes
      } ->
        [
          %AlertRow{
            alert: alert,
            direction_id: direction_id,
            displayed_headsign: displayed_headsign,
            home_stop: home_stop,
            location: location,
            mode: mode,
            routes: routes
          }
        ]
    end)
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

  @spec headways_from_rds([RDS.Headways.t()]) :: [NormalSection.HeadwayRow.t()]
  defp headways_from_rds(headway_states) do
    Enum.flat_map(headway_states, fn
      %Headways{
        routes: [route],
        direction_id: direction_id,
        range: range,
        displayed_headsign: displayed_headsign
      } ->
        [
          %HeadwayRow{
            route: route,
            direction_id: direction_id,
            range: range,
            displayed_headsign: displayed_headsign
          }
        ]
    end)
  end

  @spec departure_rows_from_state(RDS.item()) ::
          [Departure.t()] | [NormalSection.SpecialTripRow.t()]
  defp departure_rows_from_state(%Countdowns{departures: departures}), do: departures

  defp departure_rows_from_state(%FirstTrip{first_schedule: first_schedule}) do
    [
      %SpecialTripRow{
        schedule: first_schedule,
        special_trip_type: :first_trip
      }
    ]
  end

  defp departure_rows_from_state(%ServiceEnded{last_schedule: last_schedule}) do
    [
      %SpecialTripRow{
        schedule: last_schedule,
        special_trip_type: :service_ended
      }
    ]
  end

  defp departure_rows_from_state(%NoService{}), do: []

  @spec departure_time(Departure.t() | NormalSection.SpecialTripRow.t()) :: DateTime.t()
  defp departure_time(%Departure{} = departure), do: Departure.time(departure)
  defp departure_time(%SpecialTripRow{schedule: schedule}), do: Schedule.time(schedule)

  def departure_direction_id(%Departure{} = departure), do: Departure.direction_id(departure)

  def departure_direction_id(%SpecialTripRow{schedule: %Schedule{direction_id: direction_id}}),
    do: direction_id

  def departure_direction_id(%HeadwayRow{direction_id: direction_id}), do: direction_id

  def departure_direction_id(%AlertRow{direction_id: direction_id}), do: direction_id

  defp mode_to_header_title(mode) do
    case mode do
      :gl -> "Green Line"
      :ol -> "Orange Line"
      :rl -> "Red Line"
      :bl -> "Blue Line"
      :m -> "Mattapan Line"
      :sl -> "Silver Line"
      :cr -> "Commuter Rail"
      :ferry -> "Ferry"
      :bus -> "Bus"
    end
  end

  defp same_route_type?(mode, other_mode) do
    route_type = Mode.to_route_type(mode)
    other_route_type = Mode.to_route_type(other_mode)
    # In this particular case, Light Rail and Subway are both considered "Subway" route types
    if route_type in [:light_rail, :subway] and other_route_type in [:light_rail, :subway] do
      true
    else
      route_type == other_route_type
    end
  end

  defp maybe_adjust_header_for_alerts(header, rows, mode) do
    cond do
      Mode.to_route_type(mode) in [:light_rail, :subway] and
          Enum.all?(rows, fn row ->
            match?(%AlertRow{alert: %Alert{effect: :station_closure}}, row)
          end) ->
        header
        |> put_in([Access.key(:title)], "Subway Station Closed")
        |> put_in([Access.key(:subtitle)], nil)
        |> put_in([Access.key(:arrow)], "")

      Enum.all?(rows, fn row -> match?(%AlertRow{}, row) end) ->
        header
        |> put_in([Access.key(:subtitle)], nil)
        |> put_in([Access.key(:arrow)], "")

      true ->
        header
    end
  end
end
