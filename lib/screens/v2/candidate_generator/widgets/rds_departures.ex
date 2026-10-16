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
  alias ScreensConfig.Departures.{Params, Section}

  @type post_process_rows_fn_t :: ([NormalSection.row()], Section.t(), non_neg_integer() ->
                                     [NormalSection.row()])
  @type widget :: DeparturesNoData.t() | DeparturesWidget.t()

  @spec create_departure_sections(
          [RDS.data()],
          Departures.t(),
          Screen.t(),
          post_process_rows_fn_t()
        ) :: [{DeparturesWidget.section(), Section.t()}]
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

    processed_rds_and_section_data
    |> Enum.map(fn {rds_section, section} ->
      {map_to_departure_section(
         rds_section,
         section,
         total_section_count,
         post_process_rows_fn
       ), section}
    end)
    |> Enum.unzip()
  end

  defp filter_alerts_for_app_ids(rds_data, %Screen{app_id: app_id})
       when app_id in [:bus_shelter_v2, :dup_v2] do
    Enum.map(rds_data, fn
      {:ok, rds_items} ->
        {:ok, Enum.reject(rds_items, &match?(%RDS.ImpactedByAlert{}, &1))}

      other ->
        other
    end)
  end

  defp filter_alerts_for_app_ids(rds_data, _screen), do: rds_data

  defp maybe_combine_alert_sections(rds_and_sections_data, %Screen{app_id: app_id})
       when app_id in [:bus_shelter_v2, :dup_v2], do: rds_and_sections_data

  defp maybe_combine_alert_sections(rds_and_section_data, _screen) do
    combine_alert_sections(rds_and_section_data)
  end

  @spec combine_alert_sections([{RDS.data(), Section.t()}]) ::
          [{RDS.data(), Section.t()}]
  defp combine_alert_sections([
         {{:ok, [%ImpactedByAlert{alerts: [%Alert{id: id}]}]}, _section} = first,
         {{:ok, [%ImpactedByAlert{alerts: [%Alert{id: id}]}]}, _other_section}
         | rest
       ]) do
    [first | combine_alert_sections(rest)]
  end

  defp combine_alert_sections([first | rest]) do
    [first | combine_alert_sections(rest)]
  end

  defp combine_alert_sections([]), do: []

  @spec map_to_departure_section(
          RDS.data(),
          Section.t(),
          non_neg_integer(),
          post_process_rows_fn_t()
        ) ::
          DeparturesWidget.section()

  defp map_to_departure_section(
         data,
         %Section{params: %Params{mode: mode}},
         _,
         _
       )
       when data == :error or data == {:ok, []},
       do: %NoDataSection{mode: mode}

  defp map_to_departure_section(
         {:ok, items},
         %Section{header: header, layout: layout, grouping_type: grouping_type} = section,
         section_count,
         post_process_rows_fn
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
        %NormalSection{
          rows:
            items
            |> create_and_sort_rows()
            |> post_process_rows_fn.(section, section_count),
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
        %ImpactedByAlert{} -> :alert
        %ServiceEnded{} -> :service_ended
        %Headways{} -> :headways
        _ -> :other
      end)

    alert_items = Map.get(grouped_items, :alert, [])
    service_ended_items = Map.get(grouped_items, :service_ended, [])
    headway_items = Map.get(grouped_items, :headways, [])
    other_items = Map.get(grouped_items, :other, [])

    alerts_from_rds(alert_items) ++
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

  @spec alerts_from_rds([ImpactedByAlert.t()]) :: [NormalSection.AlertRow.t()]
  defp alerts_from_rds(alert_states) do
    Enum.flat_map(alert_states, fn
      %ImpactedByAlert{
        alerts: [%Alert{effect: effect} = alert | _],
        direction_id: direction_id,
        displayed_headsign: displayed_headsign,
        location: location,
        routes: [route | _]
      } ->
        [
          %AlertRow{
            alert: alert,
            direction_id: direction_id,
            displayed_headsign: displayed_headsign,
            effect: effect,
            location: location,
            route: route
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
end
