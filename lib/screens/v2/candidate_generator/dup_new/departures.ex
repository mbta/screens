defmodule Screens.V2.CandidateGenerator.DupNew.Departures do
  @moduledoc false

  import Screens.Inject

  alias Screens.V2.Departure
  alias Screens.V2.RDS
  alias Screens.V2.RDS.{Countdowns, NoDepartures}
  alias Screens.V2.WidgetInstance.Departures, as: DeparturesWidget
  alias Screens.V2.WidgetInstance.Departures.{NoDataSection, NormalSection}
  alias Screens.V2.WidgetInstance.{DeparturesNoData, OvernightDepartures}

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
      if secondary_rds_sections == [] or
           Enum.all?(secondary_rds_sections, fn
             :error -> false
             {:ok, rds_list} -> no_departures?(rds_list)
           end) do
        primary_departure_sections
      else
        create_departure_sections(secondary_rds_sections, secondary_departures)
      end

    primary_instances =
      build_instances(@primary_slot_names, primary_departure_sections, config, now)

    secondary_instances =
      build_instances(@secondary_slot_names, secondary_departure_sections, config, now)

    primary_instances ++ secondary_instances
  end

  defp create_departure_sections(rds_sections, %Departures{sections: departure_sections}) do
    section_count = length(rds_sections)

    Enum.zip(rds_sections, departure_sections)
    |> Enum.map(fn {rds_section, %Section{bidirectional: bidirectional}} ->
      map_to_departure_section(rds_section, bidirectional, section_count)
    end)
  end

  @spec map_to_departure_section(:error | {:ok, [RDS.t()]}, boolean(), number()) ::
          :error | DeparturesWidget.section()
  defp map_to_departure_section(:error, _, _), do: %NoDataSection{}

  defp map_to_departure_section({:ok, rds_list}, bidirectional, section_count) do
    num_departures_per_section = div(@max_departures_per_rotation, section_count)

    # Disable credo as this will be filled in shortly
    # credo:disable-for-next-line
    cond do
      # all headways -> HeadwaySection()
      # all overnight -> OvernightSection()

      # credo:disable-for-next-line
      # TODO: Remove this code path once we've refactored the RDS State to remove NoDepartures
      no_departures?(rds_list) ->
        %NoDataSection{}

      true ->
        %NormalSection{
          rows:
            rds_list
            |> Enum.flat_map(fn
              %RDS{state: %Countdowns{departures: departures}} ->
                departures

              %RDS{state: %NoDepartures{headways: _headways}} ->
                []
            end)
            |> Enum.sort_by(&Departure.time/1, DateTime)
            |> maybe_make_bidirectional(bidirectional)
            |> Enum.take(num_departures_per_section),
          layout: %Layout{},
          header: %Header{}
        }
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

  @spec maybe_make_bidirectional([Departure.t()], boolean()) :: [Departure.t()]
  defp maybe_make_bidirectional([], _), do: []
  defp maybe_make_bidirectional(departures, false), do: departures

  defp maybe_make_bidirectional([first | rest], true) do
    first_direction = Departure.direction_id(first)

    opposite? =
      Enum.find(rest, Enum.at(rest, 0), fn departure ->
        Departure.direction_id(departure) == 1 - first_direction
      end)

    Enum.reject([first, opposite?], &is_nil/1)
  end
end
