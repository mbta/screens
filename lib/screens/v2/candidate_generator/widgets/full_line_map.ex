defmodule Screens.V2.CandidateGenerator.Widgets.FullLineMap do
  @moduledoc false

  alias Screens.Util.Assets
  alias Screens.V2.WidgetInstance.FullLineMap, as: FullLineMapWidget
  alias ScreensConfig.Screen
  alias ScreensConfig.V2.{FullLineMap, PreFare}

  def full_line_map_instances(
        %Screen{app_params: %PreFare{full_line_map: full_line_map}} = config
      ) do
    [
      %FullLineMapWidget{
        screen: config,
        asset_urls:
          Enum.map(full_line_map, fn %FullLineMap{asset_path: asset_path} ->
            Assets.s3_asset_url(asset_path)
          end)
      }
    ]
  end
end
