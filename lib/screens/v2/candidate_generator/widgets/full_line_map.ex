defmodule Screens.V2.CandidateGenerator.Widgets.FullLineMap do
  @moduledoc false

  alias Screens.Util.Assets
  alias Screens.V2.WidgetInstance.EvergreenContent
  alias ScreensConfig.{FullLineMap, Screen}
  alias ScreensConfig.Screen.PreFare

  def full_line_map_instances(%Screen{app_params: %PreFare{full_line_map: maps}} = screen, now) do
    Enum.map(maps, fn %FullLineMap{asset_path: asset_path} ->
      %EvergreenContent{
        asset_url: Assets.s3_asset_url(asset_path),
        now: now,
        priority: [4],
        screen: screen,
        slot_names: [:paged_main_content_left],
        page_groups: [:line_maps]
      }
    end)
  end
end
