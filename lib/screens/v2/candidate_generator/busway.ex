defmodule Screens.V2.CandidateGenerator.Busway do
  @moduledoc false

  alias Screens.V2.CandidateGenerator
  alias Screens.V2.CandidateGenerator.Widgets
  alias Screens.V2.Template.Builder
  alias ScreensConfig.Screen
  alias ScreensConfig.Screen.Busway

  @behaviour CandidateGenerator

  @instance_fns [
    &Widgets.Departures.departures_instances/2,
    &Widgets.Evergreen.evergreen_content_instances/2,
    &Widgets.Header.instances/2,
    &Widgets.EmergencyTakeover.emergency_takeover_instances/2
  ]

  @impl CandidateGenerator
  def screen_template(%Screen{app_params: %Busway{template: :duo}}) do
    {
      :screen,
      %{
        screen_normal: [
          :header,
          {
            :body,
            %{
              body_normal_duo: [
                {:body_left, %{body_left_normal: [:main_content_left]}},
                {:body_right, %{body_right_normal: [:main_content_right]}}
              ],
              body_takeover: [:full_body_duo]
            }
          }
        ],
        screen_takeover: [:full_duo_screen],
        screen_split_takeover: [:full_left_screen, :full_right_screen]
      }
    }
    |> Builder.build_template()
  end

  def screen_template(%Screen{app_params: %Busway{template: :solo}}) do
    {
      :screen,
      %{
        screen_normal: [:header, {:body, %{body_normal: [:main_content]}}],
        # For ease of sharing the "duo" implementation details with Pre-Fares, Busway screens
        # use the same takeover slot logic where a solo unit is considered the "right" side.
        screen_split_takeover: [:full_right_screen]
      }
    }
    |> Builder.build_template()
  end

  @impl CandidateGenerator
  def candidate_instances(config, now \\ DateTime.utc_now(), instance_fns \\ @instance_fns) do
    CandidateGenerator.async_stream(instance_fns, & &1.(config, now), timeout: 10_000)
  end

  @impl CandidateGenerator
  def audio_only_instances(_widgets, _config), do: []
end
