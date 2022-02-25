defmodule Screens.V2.CandidateGenerator.Widgets.FullLineMap do
  @moduledoc false

  alias Screens.Config.Screen
  alias Screens.Config.V2.{PreFare, FullLineMap}
  alias Screens.V2.WidgetInstance.FullLineMap, as: FullLineMapWidget
  alias Screens.Util.Assets

  def line_map_instances(%Screen{app_params: %PreFare{full_line_map: full_line_maps}} = config) do
    Enum.map(full_line_maps, &line_map_instance(&1, config))
  end

  defp line_map_instance(%FullLineMap{asset_path: asset_path}, config) do
    %FullLineMapWidget{
      screen: config,
      asset_url: Assets.s3_asset_url(asset_path)
    }
  end
end
