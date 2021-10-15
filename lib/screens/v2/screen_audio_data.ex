defmodule Screens.V2.ScreenAudioData do
  @moduledoc false

  alias Screens.V2.ScreenData
  alias Screens.V2.WidgetInstance

  @type screen_id :: String.t()

  @spec by_screen_id(screen_id()) :: list({module(), map()})
  def by_screen_id(
        screen_id,
        get_config_fn \\ &ScreenData.get_config/1,
        fetch_data_fn \\ &ScreenData.fetch_data/2
      ) do
    config = get_config_fn.(screen_id)

    screen_id
    |> fetch_data_fn.(config)
    |> elem(1)
    |> Map.values()
    |> Enum.filter(&WidgetInstance.audio_valid_candidate?/1)
    |> Enum.sort_by(&WidgetInstance.audio_sort_key/1)
    |> Enum.map(&{WidgetInstance.audio_view(&1), WidgetInstance.audio_serialize(&1)})
  end
end
