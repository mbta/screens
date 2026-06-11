defmodule Screens.V2.CandidateGenerator.Dup do
  @moduledoc false

  alias Screens.V2.CandidateGenerator
  alias Screens.V2.CandidateGenerator.Dup.Alerts, as: AlertsGenerator
  alias Screens.V2.CandidateGenerator.Dup.Departures, as: DeparturesGenerator
  alias Screens.V2.CandidateGenerator.Widgets
  alias Screens.V2.Template.Builder

  @behaviour CandidateGenerator

  @instance_generators [
    &AlertsGenerator.alert_instances/2,
    &DeparturesGenerator.instances/2,
    &Widgets.EmergencyTakeover.emergency_takeover_instances/2,
    &Widgets.Evergreen.evergreen_content_instances/2,
    &Widgets.Header.instances/2
  ]

  @impl CandidateGenerator
  def screen_template(_screen) do
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
  def candidate_instances(config, now \\ DateTime.utc_now()) do
    CandidateGenerator.async_stream(@instance_generators, & &1.(config, now), timeout: 15_000)
  end

  @impl CandidateGenerator
  def audio_only_instances(_widgets, _config), do: []
end
