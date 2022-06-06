defmodule Screens.V2.CandidateGenerator.Widgets.Evergreen do
  @moduledoc false

  alias Screens.Config.Screen
  alias Screens.Config.V2.EvergreenContentItem
  alias Screens.V2.WidgetInstance.EvergreenContent
  alias Screens.Config.V2.{BusEink, BusShelter, GlEink, PreFare}
  alias Screens.Util.Assets

  def evergreen_content_instances(
        %Screen{app_params: %app{evergreen_content: evergreen_content}} = config,
        now \\ DateTime.utc_now()
      )
      when app in [BusEink, BusShelter, GlEink, PreFare] do
    Enum.map(evergreen_content, &evergreen_content_instance(&1, config, now))
  end

  defp evergreen_content_instance(
         %EvergreenContentItem{
           slot_names: slot_names,
           asset_path: asset_path,
           priority: priority,
           schedule: schedule
         },
         config,
         now
       ) do
    %EvergreenContent{
      screen: config,
      slot_names: slot_names,
      asset_url: Assets.s3_asset_url(asset_path),
      priority: priority,
      schedule: schedule,
      now: now
    }
  end
end
