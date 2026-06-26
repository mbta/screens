defmodule Screens.V2.CandidateGenerator.Dup.Departures do
  @moduledoc false

  alias Screens.V2.RDS

  alias Screens.V2.CandidateGenerator.Widgets.RdsDepartures
  alias Screens.V2.WidgetInstance.Departures, as: DeparturesWidget

  alias Screens.V2.WidgetInstance.Departures.{
    NoDataSection,
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

    post_process_rows_fn = fn rows, %Section{bidirectional: bidirectional}, total_section_count ->
      num_departures_per_section = div(@max_departures_per_rotation, total_section_count)

      rows
      |> RdsDepartures.maybe_make_bidirectional(bidirectional)
      |> Enum.take(num_departures_per_section)
    end

    primary_departure_sections =
      RdsDepartures.create_departure_sections(
        primary_rds_sections,
        primary_departures,
        post_process_rows_fn
      )

    secondary_departure_sections =
      if secondary_rds_sections == [] or Enum.all?(secondary_rds_sections, &(&1 == {:ok, []})) do
        primary_departure_sections
      else
        RdsDepartures.create_departure_sections(
          secondary_rds_sections,
          secondary_departures,
          post_process_rows_fn
        )
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
      RdsDepartures.build_instances(
        @primary_slot_names,
        primary_departure_sections,
        all_sections_no_data,
        all_sections_service_ended,
        config,
        now
      )

    secondary_instances =
      RdsDepartures.build_instances(
        @secondary_slot_names,
        secondary_departure_sections,
        all_sections_no_data,
        all_sections_service_ended,
        config,
        now
      )

    primary_instances ++ secondary_instances
  end
end
