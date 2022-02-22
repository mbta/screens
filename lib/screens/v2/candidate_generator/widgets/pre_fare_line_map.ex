defmodule Screens.V2.CandidateGenerator.Widgets.PreFareLineMap do
  @moduledoc false

  alias Screens.Config.Screen
  alias Screens.Config.V2.{PreFare, PreFareLineMap}
  alias Screens.V2.WidgetInstance.PreFareLineMap, as: PreFareLineMapWidget
  alias Screens.Util.Assets

  def line_map_instances(
        %Screen{app_params: %PreFare{pre_fare_line_map: pre_fare_line_maps}} = config
      ) do
    Enum.map(pre_fare_line_maps, &line_map_instance(&1, config))
  end

  defp line_map_instance(%PreFareLineMap{asset_path: asset_path}, config) do
    %PreFareLineMapWidget{
      screen: config,
      asset_url: Assets.s3_asset_url(asset_path)
    }
  end
end
