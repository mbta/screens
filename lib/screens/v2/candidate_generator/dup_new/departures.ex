defmodule Screens.V2.CandidateGenerator.DupNew.Departures do
  @moduledoc false

  import Screens.Inject

  alias Screens.Routes.Route

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
  alias ScreensConfig.Screen
  alias ScreensConfig.Screen.Dup

  @type widget :: DeparturesNoData.t() | DeparturesWidget.t() | OvernightDepartures.t()
  @rds injected(RDS)

  @max_departures_per_rotation 4

  @primary_slot_names [
    :main_content_zero,
    :main_content_one,
    :main_content_reduced_zero,
    :main_content_reduced_one
  ]
  @secondary_slot_names [:main_content_two, :main_content_reduced_two]

  @spec instances(Screen.t(), DateTime.t()) :: [widget()]
  def instances(
        %Screen{
          app_params: %Dup{
            primary_departures: primary_departures,
            secondary_departures: secondary_departures
          }
        } = config,
        now
      ) do
    primary_rds_sections = @rds.get(primary_departures, now)

    secondary_rds_sections = @rds.get(secondary_departures, now)

    primary_departure_sections =
      create_departure_sections(primary_rds_sections, primary_departures)

    secondary_departure_sections =
      if secondary_rds_sections == [] or Enum.all?(secondary_rds_sections, &(&1 == {:ok, []})) do
        primary_departure_sections
      else
        create_departure_sections(secondary_rds_sections, secondary_departures)
      end

    all_sections_no_data =
      Enum.all?(
        primary_departure_sections ++ secondary_departure_sections,
        &is_struct(&1, NoDataSection)
      )

    all_sections_service_ended =
      Enum.all?(
        primary_departure_sections ++ secondary_departure_sections,
        &is_struct(&1, OvernightSection)
      )

    primary_instances =
      build_instances(
        @primary_slot_names,
        primary_departure_sections,
        all_sections_no_data,
        all_sections_service_ended,
        config,
        now
      )

    secondary_instances =
      build_instances(
        @secondary_slot_names,
        secondary_departure_sections,
        all_sections_no_data,
        all_sections_service_ended,
        config,
        now
      )

    primary_instances ++ secondary_instances
  end

  defp create_departure_sections(rds_sections, %Departures{sections: departure_sections}) do
    section_count = length(rds_sections)

    Enum.zip(rds_sections, departure_sections)
    |> Enum.map(fn {rds_section, %Section{bidirectional: bidirectional}} ->
      map_to_departure_section(rds_section, bidirectional, section_count)
    end)
  end

  @spec map_to_departure_section(RDS.section_t(), boolean(), number()) ::
          DeparturesWidget.section()

  defp map_to_departure_section(:error, _, _), do: %NoDataSection{}

  defp map_to_departure_section({:ok, []}, _, _), do: %NoDataSection{}

  defp map_to_departure_section({:ok, rds_list}, bidirectional, section_count) do
    num_departures_per_section = div(@max_departures_per_rotation, section_count)

    cond do
      headways?(rds_list) ->
        create_headway_section(rds_list)

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
            |> Enum.map(fn %RDS{
                             state: %ServiceEnded{
                               last_scheduled_departure: last_scheduled_departure
                             }
                           } ->
              Departure.route(last_scheduled_departure)
            end)
            |> Enum.uniq()
        }

      true ->
        %NormalSection{
          rows:
            create_and_sort_rows(rds_list)
            |> maybe_make_bidirectional(bidirectional)
            |> Enum.take(num_departures_per_section),
          layout: %Layout{},
          header: %Header{}
        }
    end
  end

  defp no_service?(rds_list) do
    Enum.all?(rds_list, &is_struct(&1.state, NoService))
  end

  defp service_ended?(rds_list) do
    Enum.all?(rds_list, &is_struct(&1.state, ServiceEnded))
  end

  defp headways?([%RDS{line: line} | _] = rds_list) do
    Enum.all?(rds_list, &is_struct(&1.state, Headways))
  end

  # bidirectional -> use no headsign for the trains message
  defp create_headway_section([
         %RDS{state: %{route_id: route_id, direction_name: direction_name_one, range: range}}
         | [%RDS{state: %{route_id: route_id, direction_name: direction_name_two, range: range}}]
       ])
       when direction_name_one != direction_name_two do
    %HeadwaySection{
      route: route_id,
      time_range: range,
      headsign: nil
    }
  end

  defp create_headway_section(
         [
           %RDS{
             headsign: first_headsign,
             state: %Headways{
               route_id: first_route_id,
               direction_name: first_direction_name,
               range: first_range
             }
           }
           | _
         ] = destinations
       ) do
    %HeadwaySection{
      route: first_route_id,
      time_range: first_range,
      headsign:
        cond do
          Enum.all?(destinations, fn %RDS{headsign: headsign} ->
            headsign == first_headsign
          end) ->
            first_headsign

          Enum.all?(
            destinations,
            fn %RDS{
                 state: %Headways{route_id: other_route_id, direction_name: other_direction_name}
               } ->
              other_direction_name == first_direction_name and other_route_id == first_route_id
            end
          ) ->
            first_direction_name

          true ->
            nil
        end
    }
  end

  defp build_instances(
         slot_names,
         _departure_sections,
         true = _all_section_no_data,
         _all_section_service_ended,
         config,
         _now
       ) do
    Enum.map(slot_names, &%DeparturesNoData{screen: config, slot_name: &1})
  end

  defp build_instances(
         slot_names,
         _departure_sections,
         _all_section_no_data,
         true = _all_section_service_ended,
         config,
         _now
       ) do
    Enum.map(slot_names, &%OvernightDepartures{screen: config, slot_names: [&1]})
  end

  defp build_instances(
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
    {service_ended_rds, partially_filtered_rds} =
      Enum.split_with(rds_list, &match?(%RDS{state: %ServiceEnded{}}, &1))

    {headway_rds, rds} =
      Enum.split_with(partially_filtered_rds, &match?(%RDS{state: %Headways{}}, &1))

    sorted_departures_from_rds(rds) ++
      headways_from_rds(headway_rds) ++
      sorted_departures_from_rds(service_ended_rds, true)
  end

  @spec maybe_make_bidirectional([Departure.t()], boolean()) :: [Departure.t()]
  defp maybe_make_bidirectional([], _), do: []
  defp maybe_make_bidirectional(departures, false), do: departures

  defp maybe_make_bidirectional([first | rest], true) do
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

  defp headways_from_rds(headway_rds) do
    headway_rds
    |> Enum.group_by(fn %RDS{line: line, state: %Headways{departure: departure}} ->
      direction_id = Departure.direction_id(departure)
      route = Departure.route(departure)

      direction_name =
        route
        |> Route.normalized_direction_names()
        |> Enum.at(direction_id, nil)

      {line, direction_name}
    end)
    |> Enum.flat_map(fn
      {{_line, _direction_name}, [%RDS{state: %Headways{departure: departure, range: range}}]} ->
        [{%{departure: departure, range: range, headsign: nil}, :headways}]

      # If there are multiple headways with the same line but different headsigns, use the direction name
      {{_line, direction_name}, [%RDS{state: %Headways{departure: departure, range: range}} | _]} ->
        [{%{departure: departure, range: range, headsign: direction_name}, :headways}]
    end)
  end

  @spec departure_rows_from_state(RDS.t()) ::
          [Departure.t()] | [{Departure.t(), NormalSection.special_trip_type()}]
  defp departure_rows_from_state(%RDS{state: %Countdowns{departures: departures}}), do: departures

  defp departure_rows_from_state(%RDS{
         state: %FirstTrip{first_scheduled_departure: first_scheduled_departure}
       }) do
    [{first_scheduled_departure, :first_trip}]
  end

  defp departure_rows_from_state(%RDS{
         state: %ServiceEnded{last_scheduled_departure: last_scheduled_departure}
       }) do
    [{last_scheduled_departure, :last_trip}]
  end

  defp departure_rows_from_state(%RDS{
         state: %Headways{
           departure: departure,
           range: range
         }
       }),
       do: [{%{departure: departure, range: range}, :headways}]

  defp departure_rows_from_state(%RDS{state: %NoService{}}), do: []

  @spec departure_time(Departure.t()) :: DateTime.t()
  defp departure_time(%Departure{} = departure), do: Departure.time(departure)

  defp departure_time({first_scheduled_departure, :first_trip}),
    do: Departure.time(first_scheduled_departure)

  defp departure_time({last_scheduled_departure, :last_trip}),
    do: Departure.time(last_scheduled_departure)

  defp departure_direction_id(%Departure{} = departure), do: Departure.direction_id(departure)

  defp departure_direction_id({first_scheduled_departure, :first_trip}),
    do: Departure.direction_id(first_scheduled_departure)

  defp departure_direction_id({last_scheduled_departure, :last_trip}),
    do: Departure.direction_id(last_scheduled_departure)

  defp departure_direction_id({%{departure: departure}, :headways}),
    do: Departure.direction_id(departure)
end
