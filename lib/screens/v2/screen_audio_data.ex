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
      visual_widgets = screen |> generate_layout_fn.() |> elem(1) |> Map.values()
      audio_only_widgets = get_audio_only_instances_fn.(visual_widgets, screen)

      (visual_widgets ++ audio_only_widgets)
      |> Enum.filter(&WidgetInstance.audio_valid_candidate?/1)
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
