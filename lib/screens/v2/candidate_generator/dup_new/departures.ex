defmodule Screens.V2.CandidateGenerator.DupNew.Departures do
  @moduledoc false

  import Screens.Inject

  alias Screens.V2.RDS
  alias Screens.V2.RDS.NoDepartures
  alias Screens.V2.WidgetInstance.Departures, as: DeparturesWidget
  alias Screens.V2.WidgetInstance.Departures.NoDataSection
  alias Screens.V2.WidgetInstance.{DeparturesNoData, OvernightDepartures}
  alias ScreensConfig.Screen
  alias ScreensConfig.Screen.Dup

  @type widget :: DeparturesNoData.t() | DeparturesWidget.t() | OvernightDepartures.t()

  @rds injected(RDS)

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

    primary_departure_sections = Enum.map(primary_rds_sections, &map_to_departure_section(&1))

    secondary_departure_sections =
      if secondary_rds_sections == [] or
           Enum.all?(secondary_rds_sections, fn
             :error -> false
             {:ok, rds_list} -> no_departures?(rds_list)
           end) do
        primary_departure_sections
      else
        Enum.map(
          secondary_rds_sections,
          &map_to_departure_section(&1)
        )
      end

    primary_instances =
      build_instances(@primary_slot_names, primary_departure_sections, config, now)

    secondary_instances =
      build_instances(@secondary_slot_names, secondary_departure_sections, config, now)

    primary_instances ++ secondary_instances
  end

  @spec map_to_departure_section(:error | {:ok, [RDS.t()]}) :: :error | NoDataSection.t()
  defp map_to_departure_section(:error), do: :error
  # credo:disable-for-next-line
  # TODO: This will be where we rollup the RDS states to the different Departure sections
  # NormalSection, HeadwaySection, OvernightSection
  defp map_to_departure_section({:ok, rds_list}) do
    cond do
      # all headways -> HeadwaySection()
      # all overnight -> OvernightSection()
      # normal -> NormalSection()

      # credo:disable-for-next-line
      # TODO: Remove this code path once we've refactored the RDS State to remove NoDepartures
      no_departures?(rds_list) -> %NoDataSection{}
    end
  end

  defp no_departures?(rds_list) do
    Enum.all?(rds_list, &is_struct(&1.state, NoDepartures))
  end

  defp build_instances(slot_names, departure_sections, config, now) do
    # credo:disable-for-next-line
    # TODO: Remove this NoDataSection check once we've refactored it in RDS
    if Enum.all?(departure_sections, &(&1 == :error || is_struct(&1, NoDataSection))) do
      Enum.map(slot_names, &%DeparturesNoData{screen: config, slot_name: &1})
    else
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
end
