defmodule Screens.V2.CandidateGenerator.Dup.Departures do
  @moduledoc false

  alias Screens.Routes.Route
  alias Screens.V2.RDS

  alias Screens.V2.CandidateGenerator.Widgets.RdsDepartures
  alias Screens.V2.WidgetInstance.Departures, as: DeparturesWidget

  alias Screens.V2.WidgetInstance.Departures.{
    NoDataSection,
    NormalSection,
    NoServiceSection,
    OvernightSection
  }

  alias Screens.V2.WidgetInstance.{DeparturesNoData, DeparturesNoService, OvernightDepartures}

  alias ScreensConfig.Departures.Section
  alias ScreensConfig.Screen
  alias ScreensConfig.Screen.Dup

  import Screens.Inject
  @rds injected(RDS)

  @type widget ::
          DeparturesNoData.t()
          | DeparturesNoService.t()
          | DeparturesWidget.t()
          | OvernightDepartures.t()

  @type sections_state :: :all_no_data | :all_service_ended | :normal

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
      RdsDepartures.create_departure_sections(
        primary_rds_sections,
        primary_departures,
        &post_process_rows/4,
        now
      )

    secondary_departure_sections =
      if secondary_rds_sections == [] or Enum.all?(secondary_rds_sections, &(&1 == {:ok, []})) do
        primary_departure_sections
      else
        RdsDepartures.create_departure_sections(
          secondary_rds_sections,
          secondary_departures,
          &post_process_rows/4,
          now
        )
      end

    sections_state =
      cond do
        Enum.all?(
          primary_departure_sections ++ secondary_departure_sections,
          &is_struct(&1, NoDataSection)
        ) ->
          :all_no_data

        Enum.all?(
          primary_departure_sections ++ secondary_departure_sections,
          &is_struct(&1, OvernightSection)
        ) ->
          :all_service_ended

        true ->
          :normal
      end

    primary_instances =
      build_instances(
        @primary_slot_names,
        primary_departure_sections,
        sections_state,
        config,
        now
      )

    secondary_instances =
      build_instances(
        @secondary_slot_names,
        secondary_departure_sections,
        sections_state,
        config,
        now
      )

    primary_instances ++ secondary_instances
  end

  @spec build_instances(
          [atom()],
          [NormalSection.row()],
          sections_state(),
          Screen.t(),
          DateTime.t()
        ) ::
          [widget()]
  def(
    build_instances(
      slot_names,
      _departure_sections,
      :all_no_data,
      config,
      _now
    )
  ) do
    Enum.map(slot_names, &%DeparturesNoData{screen: config, slot_name: &1})
  end

  def build_instances(
        slot_names,
        _departure_sections,
        :all_service_ended,
        config,
        _now
      ) do
    Enum.map(slot_names, &%OvernightDepartures{screen: config, slot_names: [&1]})
  end

  def build_instances(
        slot_names,
        departure_sections,
        _sections_state,
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
          fn slot_name ->
            %DeparturesWidget{
              screen: config,
              sections: departure_sections,
              slot_names: [slot_name],
              now: now
            }
          end
        )
    end
  end

  defp post_process_rows(rows, %Section{bidirectional: bidirectional}, total_section_count, _now) do
    num_departures_per_section = div(@max_departures_per_rotation, total_section_count)

    rows
    |> RdsDepartures.maybe_make_bidirectional(bidirectional)
    |> Enum.take(num_departures_per_section)
  end
end
