defmodule Screens.V2.CandidateGenerator.DupNew.Departures do
  @moduledoc false

  import Screens.Inject

  alias Screens.Routes.Route

  alias Screens.V2.Departure
  alias Screens.V2.RDS
  alias Screens.V2.RDS.{Countdowns, FirstTrip, NoService}

  alias Screens.V2.WidgetInstance.Departures, as: DeparturesWidget

  alias Screens.V2.WidgetInstance.Departures.{
    NoDataSection,
    NormalSection,
    NoServiceSection
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

    primary_instances =
      build_instances(
        @primary_slot_names,
        primary_departure_sections,
        all_sections_no_data,
        config,
        now
      )

    secondary_instances =
      build_instances(
        @secondary_slot_names,
        secondary_departure_sections,
        all_sections_no_data,
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

    # Disable credo as this will be filled in shortly
    # credo:disable-for-next-line
    cond do
      # all headways -> HeadwaySection()
      # all overnight -> OvernightSection()
      no_service?(rds_list) ->
        %NoServiceSection{
          routes:
            rds_list
            |> Enum.flat_map(fn %RDS{state: %NoService{routes: routes}} -> routes end)
            |> Enum.uniq()
        }

      true ->
        %NormalSection{
          rows:
            rds_list
            |> Enum.flat_map(fn
              %RDS{state: %Countdowns{departures: departures}} ->
                departures

              %RDS{state: %FirstTrip{first_scheduled_departure: first_scheduled_departure}} ->
                [{first_scheduled_departure, :first_trip}]

              %RDS{state: %NoService{}} ->
                []
            end)
            |> Enum.sort_by(
              fn
                %Departure{} = departure ->
                  Departure.time(departure)

                {first_scheduled_departure, :first_trip} ->
                  Departure.time(first_scheduled_departure)
              end,
              DateTime
            )
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

  defp build_instances(slot_names, _departure_sections, true = _all_section_no_data, config, _now) do
    Enum.map(slot_names, &%DeparturesNoData{screen: config, slot_name: &1})
  end

  defp build_instances(slot_names, departure_sections, _all_section_no_data, config, now) do
    # Disable credo as this will be filled in shortly
    # credo:disable-for-next-line
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

  @spec maybe_make_bidirectional([Departure.t()], boolean()) :: [Departure.t()]
  defp maybe_make_bidirectional([], _), do: []
  defp maybe_make_bidirectional(departures, false), do: departures

  defp maybe_make_bidirectional([first | rest], true) do
    first_direction =
      case first do
        %Departure{} ->
          Departure.direction_id(first)

        {first_scheduled_departure, :first_trip} ->
          Departure.direction_id(first_scheduled_departure)
      end

    opposite? =
      Enum.find(rest, Enum.at(rest, 0), fn
        %Departure{} = departure ->
          Departure.direction_id(departure) == 1 - first_direction

        {first_scheduled_departure, :first_trip} ->
          Departure.direction_id(first_scheduled_departure) == 1 - first_direction
      end)

    Enum.reject([first, opposite?], &is_nil/1)
  end
end
