defmodule Screens.V2.CandidateGenerator.Dup do
  @moduledoc false

  alias Screens.Config.Screen
  alias Screens.Config.V2.Dup
  alias Screens.Config.V2.Header.CurrentStopId
  alias Screens.Stops.Stop
  alias Screens.V2.CandidateGenerator
  alias Screens.V2.Template.Builder
  alias Screens.V2.WidgetInstance.{NormalHeader, Placeholder}

  @behaviour CandidateGenerator

  @impl CandidateGenerator
  def screen_template do
    {:screen,
     %{
       screen_normal: [
         {:rotation_zero,
          %{
            body_normal_zero: [
              :header,
              :main_content_primary,
              :inline_alert_zero
            ],
            body_takeover_one: [:full_body_zero]
          }},
         {:rotation_one,
          %{
            body_normal_one: [
              :header,
              :main_content_primary
            ],
            body_takeover_one: [:full_body_one]
          }},
         {:rotation_two,
          %{
            body_normal_two: [
              :header,
              :main_content_secondary,
              :inline_alert_two
            ],
            body_takeover_two: [:full_body_two]
          }}
       ],
       screen_takeover: [:full_screen]
     }}
    |> Builder.build_template()
  end

  @impl CandidateGenerator
  def candidate_instances(config, now \\ DateTime.utc_now()) do
    [fn -> header_instances(config, now) end, fn -> placeholder_instances() end]
    |> Task.async_stream(& &1.(), ordered: false, timeout: :infinity)
    |> Enum.flat_map(fn {:ok, instances} -> instances end)
  end

  @impl CandidateGenerator
  def audio_only_instances(_widgets, _config), do: []

  defp header_instances(
         config,
         now,
         fetch_stop_name_fn \\ &Stop.fetch_stop_name/1
       ) do
    %Screen{app_params: %Dup{header: %CurrentStopId{stop_id: stop_id}}} = config

    stop_name = fetch_stop_name_fn.(stop_id)

    for _ <- 1..3, do: %NormalHeader{screen: config, text: stop_name, time: now}
  end

  defp placeholder_instances do
    [
      %Placeholder{slot_names: [:main_content_primary], color: :grey},
      %Placeholder{slot_names: [:main_content_secondary], color: :green}
    ]
  end
end
