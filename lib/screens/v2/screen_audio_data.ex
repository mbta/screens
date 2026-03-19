defmodule Screens.V2.ScreenAudioData do
  @moduledoc false

  alias Screens.V2.ScreenData
  alias Screens.V2.ScreenData.Parameters
  alias Screens.V2.WidgetInstance
  alias ScreensConfig.Screen

  @spec get(Screen.t()) :: list({module(), map()})
  def get(
        screen,
        generate_layout_fn \\ &ScreenData.Layout.generate/1,
        get_audio_only_instances_fn \\ &get_audio_only_instances/2,
        now \\ DateTime.utc_now()
      ) do
    if Parameters.audio_enabled?(screen, now) do
      visual_widgets_with_audio_equivalence =
        screen
        |> generate_layout_fn.()
        |> elem(1)
        |> Map.values()
        |> Enum.filter(&WidgetInstance.audio_valid_candidate?/1)

      audio_only_widgets =
        visual_widgets_with_audio_equivalence
        |> get_audio_only_instances_fn.(screen)
        |> Enum.filter(&WidgetInstance.audio_valid_candidate?/1)

      (visual_widgets_with_audio_equivalence ++ audio_only_widgets)
      |> Enum.sort_by(&WidgetInstance.audio_sort_key/1)
      |> Enum.map(&{WidgetInstance.audio_view(&1), WidgetInstance.audio_serialize(&1)})
    else
      []
    end
  end

  @spec get_volume(Screen.t()) :: {:ok, float()} | :error
  def get_volume(screen, now \\ DateTime.utc_now()) do
    case Parameters.audio_volume(screen, now) do
      nil -> :error
      volume -> {:ok, volume}
    end
  end

  defp get_audio_only_instances(widgets, screen) do
    Parameters.candidate_generator(screen).audio_only_instances(widgets, screen)
  end
end
