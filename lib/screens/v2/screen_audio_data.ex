defmodule Screens.V2.ScreenAudioData do
  @moduledoc false

  alias Screens.Config.Cache
  alias Screens.V2.ScreenData
  alias Screens.V2.ScreenData.Parameters
  alias Screens.V2.WidgetInstance

  @type screen_id :: String.t()

  @spec by_screen_id(screen_id()) :: list({module(), map()})
  def by_screen_id(
        screen_id,
        get_config_fn \\ &Cache.screen/1,
        generate_layout_fn \\ &ScreenData.Layout.generate/1,
        get_audio_only_instances_fn \\ &get_audio_only_instances/2,
        now \\ DateTime.utc_now()
      ) do
    config = get_config_fn.(screen_id)

    if Parameters.audio_enabled?(config, now) do
      visual_widgets_with_audio_equivalence =
        config
        |> generate_layout_fn.()
        |> elem(1)
        |> Map.values()
        |> Enum.filter(&WidgetInstance.audio_valid_candidate?/1)

      audio_only_widgets =
        visual_widgets_with_audio_equivalence
        |> get_audio_only_instances_fn.(config)
        |> Enum.filter(&WidgetInstance.audio_valid_candidate?/1)

      (visual_widgets_with_audio_equivalence ++ audio_only_widgets)
      |> Enum.sort_by(&WidgetInstance.audio_sort_key/1)
      |> Enum.map(&{WidgetInstance.audio_view(&1), WidgetInstance.audio_serialize(&1)})
    else
      []
    end
  end

  @spec volume_by_screen_id(screen_id()) :: {:ok, float()} | :error
  def volume_by_screen_id(
        screen_id,
        get_config_fn \\ &Cache.screen/1,
        now \\ DateTime.utc_now()
      ) do
    case screen_id |> get_config_fn.() |> Parameters.audio_volume(now) do
      nil -> :error
      volume -> {:ok, volume}
    end
  end

  defp get_audio_only_instances(visual_widgets_with_audio_equivalence, config) do
    Parameters.candidate_generator(config).audio_only_instances(
      visual_widgets_with_audio_equivalence,
      config
    )
  end
end
