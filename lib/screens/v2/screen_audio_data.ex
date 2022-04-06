defmodule Screens.V2.ScreenAudioData do
  @moduledoc false

  alias Screens.Config.Screen
  alias Screens.Config.V2.{Audio, BusShelter, PreFare}
  alias Screens.V2.ScreenData
  alias Screens.V2.ScreenData.Parameters
  alias Screens.V2.WidgetInstance

  @type screen_id :: String.t()

  @spec by_screen_id(screen_id()) :: list({module(), map()}) | :error
  def by_screen_id(
        screen_id,
        get_config_fn \\ &ScreenData.get_config/1,
        fetch_data_fn \\ &ScreenData.fetch_data/1,
        get_audio_only_instances_fn \\ &get_audio_only_instances/2,
        now \\ DateTime.utc_now()
      ) do
    config = get_config_fn.(screen_id)
    {:ok, now} = DateTime.shift_zone(now, "America/New_York")

    case config do
      %Screen{app_params: %app{}} when app not in [BusShelter, PreFare] ->
        :error

      %Screen{app_params: %_app{audio: audio}} ->
        if date_in_range?(audio, now) do
          config
          |> fetch_data_fn.()
          |> elem(1)
          |> Map.values()
          |> Enum.filter(&WidgetInstance.audio_valid_candidate?/1)
          |> then(&(&1 ++ get_audio_only_instances_fn.(&1, config)))
          |> Enum.sort_by(&WidgetInstance.audio_sort_key/1)
          |> Enum.map(&{WidgetInstance.audio_view(&1), WidgetInstance.audio_serialize(&1)})
        else
          []
        end
    end
  end

  @spec volume_by_screen_id(screen_id()) :: {:ok, float()} | :error
  def volume_by_screen_id(
        screen_id,
        get_config_fn \\ &ScreenData.get_config/1,
        now \\ DateTime.utc_now()
      ) do
    config = get_config_fn.(screen_id)
    {:ok, now} = DateTime.shift_zone(now, "America/New_York")

    case config do
      %Screen{app_params: %app{}} when app not in [BusShelter] ->
        :error

      %Screen{app_params: %_app{audio: audio}} ->
        {:ok, get_volume(audio, now)}
    end
  end

  defp get_audio_only_instances(visual_widgets_with_audio_equivalence, config) do
    candidate_generator = Parameters.get_candidate_generator(config)

    candidate_generator.audio_only_instances(
      visual_widgets_with_audio_equivalence,
      config
    )
  end

  defp get_volume(
         %Audio{
           daytime_start_time: daytime_start_time,
           daytime_stop_time: daytime_stop_time,
           daytime_volume: daytime_volume,
           nighttime_volume: nighttime_volume
         },
         now
       ) do
    if time_in_range?(now, daytime_start_time, daytime_stop_time),
      do: daytime_volume,
      else: nighttime_volume
  end

  defp date_in_range?(
         %Audio{
           start_time: start_time,
           stop_time: stop_time,
           days_active: days_active
         },
         dt
       ) do
    Date.day_of_week(dt) in days_active and
      time_in_range?(DateTime.to_time(dt), start_time, stop_time)
  end

  def time_in_range?(t, start_time, stop_time) do
    if Time.compare(start_time, stop_time) in [:lt, :eq] do
      # The range exists within a single day starting/ending at midnight
      Time.compare(start_time, t) in [:lt, :eq] and Time.compare(stop_time, t) == :gt
    else
      # The range crosses midnight, e.g. start: 5am, stop: 1am
      Time.compare(start_time, t) in [:lt, :eq] or Time.compare(stop_time, t) == :gt
    end
  end
end
