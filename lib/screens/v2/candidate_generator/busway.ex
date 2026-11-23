defmodule Screens.V2.CandidateGenerator.Busway do
  @moduledoc false

  alias Screens.V2.CandidateGenerator
  alias Screens.V2.CandidateGenerator.Widgets
  alias Screens.V2.Template.Builder
  alias ScreensConfig.Screen
  alias ScreensConfig.Screen.Busway

  @behaviour CandidateGenerator

  @instance_fns [
    &Widgets.Lcd.RealtimeDepartures.departures_instances/2,
    &Widgets.Evergreen.evergreen_content_instances/2,
    &Widgets.Header.instances/2,
    &Widgets.EmergencyTakeover.emergency_takeover_instances/2
  ]

  # Busway screens support two templates, :duo and :solo, corresponding to the number of display sections.
  # Each template has its own layout structure to place widgets.
  @impl CandidateGenerator
  def screen_template(%Screen{app_params: %Busway{template: :duo}}) do
    {
      # :screen is the base Region to fill, which contains 3 possible Layouts:
      #    screen_normal	        - Standard departure info when no active evergreen content or emergency takeover
      #    screen_takeover	      - Full-screen configured evergreen content or emergency takeover
      #    screen_split_takeover	- Left/right split. Departures can also fill one side while the other side is taken over.
      :screen,
      %{
        # screen_normal is a Region with only one layout option - :header and :body
        screen_normal: [
          # :header is a Slot. Widgets can be placed directly into :header.
          :header,
          {
            # :body is a nested Region, with two possible Layouts: body_normal_duo and body_takeover.
            :body,
            %{
              body_normal_duo: [
                # :body_left and :body_right are Regions, which each contain one possible Layout, eg: %{body_left_normal: [:main_content_left]}
                # :main_content_left and :main_content_right are the Slots that widgets can be placed into.
                {:body_left, %{body_left_normal: [:main_content_left]}},
                {:body_right, %{body_right_normal: [:main_content_right]}}
              ],
              # body_takeover is a Region with one possible Layout, comprised of the single Slot :full_body_duo
              body_takeover: [:full_body_duo]
            }
          }
        ],
        # screen_takeover contains one Layout comprised of a single slot, :full_duo_screen, for full-screen content
        screen_takeover: [:full_duo_screen],
        # screen_split_takeover contains one Layout comprised of two slots
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
