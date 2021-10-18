defmodule Screens.V2.ScreenAudioData do
  @moduledoc false

  alias Screens.Config.Screen
  alias Screens.Config.V2.{Audio, BusShelter}
  alias Screens.V2.ScreenData
  alias Screens.V2.WidgetInstance

  @type screen_id :: String.t()

  @spec by_screen_id(screen_id()) :: list({module(), map()}) | :error
  def by_screen_id(
        screen_id,
        get_config_fn \\ &ScreenData.get_config/1,
        fetch_data_fn \\ &ScreenData.fetch_data/2,
        now \\ DateTime.utc_now()
      ) do
    config = get_config_fn.(screen_id)

    case config do
      %Screen{app_params: %app{}} when app not in [BusShelter] ->
        :error

      %Screen{app_params: %_app{audio: nil}} ->
        :error

      %Screen{app_params: %_app{audio: audio}} ->
        if date_out_of_range?(audio, now) do
          []
        else
          screen_id
          |> fetch_data_fn.(config)
          |> elem(1)
          |> Map.values()
          |> Enum.filter(&WidgetInstance.audio_valid_candidate?/1)
          |> Enum.sort_by(&WidgetInstance.audio_sort_key/1)
          |> Enum.map(&{WidgetInstance.audio_view(&1), WidgetInstance.audio_serialize(&1)})
        end
    end
  end

  defp date_out_of_range?(
         %Audio{
           start_time: start_time,
           stop_time: stop_time,
           days_active: days_active
         },
         now
       ) do
    {:ok, now_eastern} = DateTime.shift_zone(now, "America/New_York")

    Date.day_of_week(now_eastern) not in days_active or
      Time.compare(start_time, now_eastern) == :gt or
      Time.compare(stop_time, now_eastern) == :lt
  end
end
