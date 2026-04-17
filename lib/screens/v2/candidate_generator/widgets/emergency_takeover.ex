defmodule Screens.V2.CandidateGenerator.Widgets.EmergencyTakeover do
  @moduledoc false

  alias Screens.V2.WidgetInstance.EvergreenContent
  alias ScreensConfig.EmergencyTakeover
  alias ScreensConfig.Screen
  alias ScreensConfig.Screen.{Busway, Dup, PreFare}

  @spec emergency_takeover_instances(Screen.t(), DateTime.t()) :: [EvergreenContent.t()]
  def emergency_takeover_instances(config, now \\ DateTime.utc_now())

  def emergency_takeover_instances(
        %Screen{app_params: %{emergency_takeover: nil}} =
          _config,
        _now
      ),
      do: []

  def emergency_takeover_instances(
        %Screen{app_params: %{emergency_takeover: emergency_takeover} = app} =
          config,
        now
      ) do
    case app do
      %PreFare{template: :duo} -> [:full_left_screen, :full_right_screen]
      %PreFare{template: :solo} -> [:full_right_screen]
      %Busway{} -> [:full_screen]
      %Dup{} -> [:full_rotation_zero, :full_rotation_one, :full_rotation_two]
    end
    |> Enum.map(&evergreen_content_for_emergency_takeover(emergency_takeover, config, now, &1))
  end

  @spec evergreen_content_for_emergency_takeover(
          EmergencyTakeover.t(),
          Screen.t(),
          DateTime.t(),
          atom()
        ) ::
          EvergreenContent.t()
  defp evergreen_content_for_emergency_takeover(
         %EmergencyTakeover{text_for_audio: text_for_audio, visual_asset_path: visual_asset_path},
         config,
         now,
         slot_name
       ) do
    %EvergreenContent{
      screen: config,
      slot_names: [slot_name],
      asset_url: visual_asset_path,
      priority: [0],
      now: now,
      text_for_audio: text_for_audio,
      audio_priority: [0]
    }
  end
end
