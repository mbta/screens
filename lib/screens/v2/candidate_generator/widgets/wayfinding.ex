defmodule Screens.V2.CandidateGenerator.Widgets.Wayfinding do
  @moduledoc false

  alias Screens.Util.Assets
  alias Screens.V2.WidgetInstance.Wayfinding
  alias ScreensConfig.Screen
  alias ScreensConfig.Screen.PreFare
  alias ScreensConfig.Wayfinding, as: WayfindingConfig

  def wayfinding_instances(%Screen{app_params: %PreFare{wayfinding: nil}}, _now), do: []

  def wayfinding_instances(
        %Screen{
          app_params: %PreFare{
            departures: departures,
            wayfinding: %WayfindingConfig{
              asset_url: asset_url,
              placement: placement,
              header_text: header_text,
              text_for_audio: text_for_audio
            }
          }
        } = screen,
        _now
      ) do
    slot_name =
      cond do
        departures == nil -> :main_content_left
        placement == :top -> :body_left_top
        placement == :bottom -> :body_left_bottom
      end

    [
      %Wayfinding{
        screen: screen,
        asset_url: Assets.s3_asset_url(asset_url),
        header_text: header_text,
        text_for_audio: text_for_audio,
        slot_names: [slot_name]
      }
    ]
  end
end
