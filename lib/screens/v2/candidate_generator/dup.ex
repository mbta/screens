defmodule Screens.V2.CandidateGenerator.Dup do
  @moduledoc false

  alias Screens.Config.Screen
  alias Screens.Config.V2.Dup
  alias Screens.Config.V2.Header.{CurrentStopId, CurrentStopName}
  alias Screens.Stops.Stop
  alias Screens.V2.CandidateGenerator
  alias Screens.V2.CandidateGenerator.Dup.Alerts, as: AlertsInstances
  alias Screens.V2.CandidateGenerator.Dup.Departures, as: DeparturesInstances
  alias Screens.V2.CandidateGenerator.Widgets
  alias Screens.V2.Template.Builder
  alias Screens.V2.WidgetInstance.NormalHeader

  @behaviour CandidateGenerator

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
        evergreen_content_instances_fn \\ &Widgets.Evergreen.evergreen_content_instances/1,
        departures_instances_fn \\ &DeparturesInstances.departures_instances/2,
        alerts_instances_fn \\ &AlertsInstances.alert_instances/2
      ) do
    [
      fn -> header_instances(config, now, fetch_stop_name_fn) end,
      fn -> alerts_instances_fn.(config, now) end,
      fn -> departures_instances_fn.(config, now) end,
      fn -> evergreen_content_instances_fn.(config) end
    ]
    |> Task.async_stream(& &1.(), ordered: false, timeout: 30_000)
    |> Enum.flat_map(fn {:ok, instances} -> instances end)
  end

  @impl CandidateGenerator
  def audio_only_instances(_widgets, _config), do: []

  def header_instances(
        config,
        now,
        fetch_stop_name_fn
      ) do
    %Screen{app_params: %Dup{header: header_config}} = config

    stop_name =
      case header_config do
        %CurrentStopId{stop_id: stop_id} ->
          case fetch_stop_name_fn.(stop_id) do
            nil -> []
            stop_name -> stop_name
          end

        %CurrentStopName{stop_name: stop_name} ->
          stop_name
      end

    List.duplicate(%NormalHeader{screen: config, icon: :logo, text: stop_name, time: now}, 3)
  end
end
