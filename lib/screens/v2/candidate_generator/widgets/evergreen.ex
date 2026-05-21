defmodule Screens.V2.CandidateGenerator.Widgets.Evergreen do
  @moduledoc false

  alias Screens.Util.Assets
  alias Screens.V2.WidgetInstance.EvergreenContent
  alias ScreensConfig.{AlertSchedule, EvergreenContentItem, Screen}

  import Screens.Inject
  @alert injected(Screens.Alerts.Alert)

  def evergreen_content_instances(
        %Screen{app_params: %_app{evergreen_content: evergreen_content}} = config,
        now \\ DateTime.utc_now()
      ) do
    alert_ids =
      Enum.flat_map(evergreen_content, fn
        %EvergreenContentItem{schedule: %AlertSchedule{alert_ids: alert_ids}} -> alert_ids
        _ -> []
      end)

    alerts =
      case @alert.fetch(ids: alert_ids) do
        {:ok, alerts} -> alerts
        :error -> []
      end

    Enum.map(evergreen_content, &evergreen_content_instance(&1, alerts, config, now))
  end

  defp evergreen_content_instance(
         %EvergreenContentItem{
           slot_names: slot_names,
           asset_path: asset_path,
           priority: priority,
           schedule: schedule,
           text_for_audio: text_for_audio,
           audio_priority: audio_priority
         },
         alerts,
         config,
         now
       ) do
    %EvergreenContent{
      screen: config,
      slot_names: Enum.map(slot_names, &String.to_existing_atom/1),
      alerts: alerts,
      asset_url: Assets.s3_asset_url(asset_path),
      priority: priority,
      schedule: schedule,
      now: now,
      text_for_audio: text_for_audio,
      audio_priority: audio_priority
    }
  end
end
