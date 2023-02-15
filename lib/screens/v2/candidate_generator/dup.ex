defmodule Screens.V2.CandidateGenerator.Dup do
  @moduledoc false

  alias Screens.Config.V2.Departures.Query.Params
  alias Screens.Alerts.Alert
  alias Screens.Config.Screen
  alias Screens.Config.V2.Departures
  alias Screens.Config.V2.Departures.{Headway, Query, Section}
  alias Screens.Config.V2.Dup
  alias Screens.Config.V2.Header.CurrentStopId
  alias Screens.SignsUiConfig
  alias Screens.Stops.Stop
  alias Screens.V2.CandidateGenerator
  alias Screens.V2.CandidateGenerator.Widgets
  alias Screens.V2.Template.Builder
  alias Screens.V2.WidgetInstance.Departures, as: DeparturesWidget
  alias Screens.V2.WidgetInstance.{DeparturesNoData, NormalHeader, Placeholder}

  @behaviour CandidateGenerator

  @branch_stations ["place-kencl", "place-jfk", "place-coecl"]
  @branch_terminals [
    "Boston College",
    "Cleveland Circle",
    "Riverside",
    "Heath Street",
    "Ashmont",
    "Braintree"
  ]

  @impl CandidateGenerator
  def screen_template do
    {:screen,
     %{
       screen_normal: [
         {:rotation_zero,
          %{
            rotation_normal_zero: [
              :header_zero,
              {:body_zero,
               %{
                 body_normal_zero: [
                   :main_content_zero
                 ],
                 body_split_zero: [
                   :main_content_reduced_zero,
                   :bottom_pane_zero
                 ]
               }}
            ],
            rotation_takeover_zero: [:full_rotation_zero]
          }},
         {:rotation_one,
          %{
            rotation_normal_one: [
              :header_one,
              {:body_one,
               %{
                 body_normal_one: [:main_content_one],
                 body_split_one: [
                   :main_content_reduced_one,
                   :bottom_pane_one
                 ]
               }}
            ],
            rotation_takeover_one: [:full_rotation_one]
          }},
         {:rotation_two,
          %{
            rotation_normal_two: [
              :header_two,
              {:body_two,
               %{
                 body_normal_two: [
                   :main_content_two
                 ],
                 body_split_two: [
                   :main_content_reduced_two,
                   :bottom_pane_two
                 ]
               }}
            ],
            rotation_takeover_two: [:full_rotation_two]
          }}
       ]
     }}
    |> Builder.build_template()
  end

  @impl CandidateGenerator
  def candidate_instances(
        config,
        now \\ DateTime.utc_now(),
        fetch_stop_name_fn \\ &Stop.fetch_stop_name/1,
        fetch_section_departures_fn \\ &Widgets.Departures.fetch_section_departures/1
      ) do
    [
      fn -> header_instances(config, now, fetch_stop_name_fn) end,
      fn -> placeholder_instances() end,
      fn ->
        departures_instances(config, fetch_section_departures_fn)
      end
    ]
    |> Task.async_stream(& &1.(), ordered: false, timeout: :infinity)
    |> Enum.flat_map(fn {:ok, instances} -> instances end)
  end

  @impl CandidateGenerator
  def audio_only_instances(_widgets, _config), do: []

  def header_instances(
        config,
        now,
        fetch_stop_name_fn
      ) do
    %Screen{app_params: %Dup{header: %CurrentStopId{stop_id: stop_id}}} = config

    stop_name = fetch_stop_name_fn.(stop_id)

    List.duplicate(%NormalHeader{screen: config, icon: :logo, text: stop_name, time: now}, 3)
  end

  def departures_instances(
        %Screen{
          app_params: %Dup{
            primary_departures: %Departures{sections: primary_sections},
            secondary_departures: %Departures{sections: secondary_sections}
          }
        } = config,
        fetch_section_departures_fn
      ) do
    primary_sections_data = get_sections_data(primary_sections, fetch_section_departures_fn)

    secondary_sections_data =
      if secondary_sections == [] do
        primary_sections_data
      else
        get_sections_data(secondary_sections, fetch_section_departures_fn)
      end

    primary_departures_instances =
      sections_data_to_departure_instances(
        config,
        primary_sections_data,
        [:main_content_zero, :main_content_one]
      )

    secondary_departures_instances =
      sections_data_to_departure_instances(
        config,
        secondary_sections_data,
        [:main_content_two]
      )

    primary_departures_instances ++ secondary_departures_instances
  end

  defp sections_data_to_departure_instances(config, sections_data, slot_ids) do
    if Enum.any?(sections_data, &(&1 == :error)) do
      %DeparturesNoData{screen: config, show_alternatives?: true}
    else
      sections =
        Enum.map(sections_data, fn %{departures: departures, pill: pill} ->
          visible_departures =
            if length(sections_data) > 1 do
              Enum.take(departures, 2)
            else
              Enum.take(departures, 4)
            end

          if visible_departures == [] do
            %{type: :headway_section, pill: pill}
          else
            %{type: :normal_section, rows: visible_departures}
          end
        end)

      Enum.map(slot_ids, fn slot_id ->
        %DeparturesWidget{
          screen: config,
          section_data: sections,
          slot_names: [slot_id]
        }
      end)
    end
  end

  defp get_sections_data(sections, fetch_section_departures_fn) do
    Enum.map(sections, fn %Departures.Section{
                            headway: %Departures.Headway{pill: pill}
                          } = section ->
      {:ok, data} = section |> fetch_section_departures_fn.()
      %{departures: data, pill: pill}
    end)
  end

  defp placeholder_instances do
    [
      %Placeholder{slot_names: [:main_content_one], color: :orange},
      %Placeholder{slot_names: [:main_content_reduced_two], color: :green},
      %Placeholder{slot_names: [:bottom_pane_two], color: :red}
    ]
  end

  defp fetch_headway_mode(_, _, [], _), do: :inactive

  defp fetch_headway_mode(
         stop_ids,
         %{sign_ids: sign_ids, headway_id: headway_id},
         [section_alert | _],
         current_time
       ) do
    interpreted_alert = interpret_alert(section_alert, stop_ids)

    non_branch_temporary_terminal? =
      temporary_terminal?(interpreted_alert) and
        not (branch_station?(stop_ids) and branch_alert?(interpreted_alert))

    signs_ui_headways? = SignsUiConfig.State.all_signs_in_headway_mode?(sign_ids)
    headway_mode? = non_branch_temporary_terminal? or signs_ui_headways?

    if headway_mode? do
      time_ranges = SignsUiConfig.State.time_ranges(headway_id)
      current_time_period = Screens.Util.time_period(current_time)

      case time_ranges do
        %{^current_time_period => {lo, hi}} ->
          {:active, {lo, hi}, interpreted_alert.headsign}

        _ ->
          :inactive
      end
    else
      :inactive
    end
  end

  defp temporary_terminal?(section_alert) do
    # NB: There aren't currently any DUPs at permanent terminals, so we assume all
    # terminals are temporary. In the future, we'll need to check that the boundary
    # isn't a normal terminal.
    match?(%{region: :boundary}, section_alert)
  end

  defp branch_station?(stop_ids) do
    case stop_ids do
      [parent_station_id] -> parent_station_id in MapSet.new(@branch_stations)
      _ -> false
    end
  end

  defp branch_alert?(%{headsign: headsign}) do
    headsign in MapSet.new(@branch_terminals)
  end

  defp interpret_alert(alert, [parent_stop_id]) do
    informed_stop_ids = Enum.into(alert.informed_entities, MapSet.new(), & &1.stop)

    {region, headsign} =
      :screens
      |> Application.get_env(:dup_alert_headsign_matchers)
      |> Map.get(parent_stop_id)
      |> Enum.find_value({:inside, nil}, fn {informed, not_informed, headsign} ->
        if alert_region_match?(to_set(informed), to_set(not_informed), informed_stop_ids),
          do: {:boundary, headsign},
          else: false
      end)

    %{
      cause: alert.cause,
      effect: alert.effect,
      region: region,
      headsign: headsign
    }
  end

  defp to_set(stop_id) when is_binary(stop_id), do: MapSet.new([stop_id])
  defp to_set(stop_ids) when is_list(stop_ids), do: MapSet.new(stop_ids)
  defp to_set(%MapSet{} = already_a_set), do: already_a_set

  defp alert_region_match?(informed, not_informed, informed_stop_ids) do
    MapSet.subset?(informed, informed_stop_ids) and
      MapSet.disjoint?(not_informed, informed_stop_ids)
  end
end
