defmodule Screens.V2.ScreenData.Parameters do
  @moduledoc false

  alias Screens.Util
  alias Screens.V2.CandidateGenerator
  alias Screens.V2.ScreenData.Static
  alias Screens.V2.ScreenData.Static.PeriodicAudio
  alias ScreensConfig.Screen

  @all_times {~T[00:00:00], ~T[23:59:59]}

  @static_params %{
    bus_eink_v2: %Static{
      audio_active_time: @all_times,
      candidate_generator: CandidateGenerator.BusEink,
      refresh_rate: 30
    },
    bus_shelter_v2: %Static{
      audio_active_time: {~T[04:45:00], ~T[01:45:00]},
      candidate_generator: CandidateGenerator.BusShelter,
      periodic_audio: %PeriodicAudio{
        day_volume: 1.0,
        interval_minutes: 5,
        night_time: {~T[21:00:00], ~T[07:00:00]},
        night_volume: 0.5
      },
      refresh_rate: 20
    },
    busway_v2: %Static{
      audio_active_time: @all_times,
      candidate_generator: CandidateGenerator.Busway,
      refresh_rate: 15
    },
    dup_v2: %Static{
      candidate_generator: CandidateGenerator.Dup,
      refresh_rate: 30,
      variants: %{"new_departures" => CandidateGenerator.DupNew}
    },
    elevator_v2: %Static{
      candidate_generator: CandidateGenerator.Elevator,
      refresh_rate: 30
    },
    gl_eink_v2: %Static{
      audio_active_time: @all_times,
      candidate_generator: CandidateGenerator.GlEink,
      refresh_rate: 30
    },
    pre_fare_v2: %Static{
      audio_active_time: {~T[04:45:00], ~T[01:45:00]},
      candidate_generator: CandidateGenerator.PreFare,
      refresh_rate: 20
    }
  }

  @typep static_params :: %{Screen.app_id() => Static.t()}

  @spec audio_enabled?(Screen.t(), DateTime.t()) :: boolean()
  @spec audio_enabled?(Screen.t(), DateTime.t(), static_params()) :: boolean()
  def audio_enabled?(%Screen{app_id: app_id}, now, static_params \\ @static_params) do
    case Map.fetch!(static_params, app_id) do
      %Static{audio_active_time: nil} ->
        false

      %Static{audio_active_time: {start_time, end_time}} ->
        Util.time_in_range?(now, start_time, end_time)
    end
  end

  @spec audio_interval_minutes(Screen.t(), static_params()) :: pos_integer() | nil
  def audio_interval_minutes(screen, static_params \\ @static_params)

  def audio_interval_minutes(
        %Screen{
          app_id: app_id,
          app_params: %{audio: %ScreensConfig.V2.Audio{interval_enabled: interval_enabled}}
        },
        static_params
      ) do
    if interval_enabled, do: fetch_interval_minutes(app_id, static_params), else: nil
  end

  def audio_interval_minutes(%Screen{app_id: app_id}, static_params) do
    fetch_interval_minutes(app_id, static_params)
  end

  defp fetch_interval_minutes(app_id, static_params) do
    case Map.fetch!(static_params, app_id) do
      %Static{periodic_audio: nil} -> nil
      %Static{periodic_audio: %PeriodicAudio{interval_minutes: interval}} -> interval
    end
  end

  @spec audio_interval_offset_seconds(Screen.t()) :: pos_integer() | nil
  def audio_interval_offset_seconds(%Screen{
        app_params: %ScreensConfig.V2.BusShelter{
          audio: %ScreensConfig.V2.Audio{interval_offset_seconds: interval_offset_seconds}
        }
      }) do
    interval_offset_seconds
  end

  def audio_interval_offset_seconds(_screen), do: nil

  @spec audio_volume(Screen.t(), DateTime.t()) :: float() | nil
  @spec audio_volume(Screen.t(), DateTime.t(), static_params()) :: float() | nil
  def audio_volume(%Screen{app_id: app_id}, now, static_params \\ @static_params) do
    case Map.fetch!(static_params, app_id) do
      %Static{periodic_audio: nil} ->
        nil

      %Static{
        periodic_audio: %PeriodicAudio{
          day_volume: day_volume,
          night_time: {night_start, night_end},
          night_volume: night_volume
        }
      } ->
        if now |> Util.to_eastern() |> Util.time_in_range?(night_start, night_end),
          do: night_volume,
          else: day_volume
    end
  end

  @callback candidate_generator(Screen.t()) :: module()
  @callback candidate_generator(Screen.t(), String.t() | nil) :: module()
  @callback candidate_generator(Screen.t(), String.t() | nil, static_params()) :: module()
  def candidate_generator(
        %Screen{app_id: app_id},
        variant \\ nil,
        static_params \\ @static_params
      ) do
    case Map.fetch!(static_params, app_id) do
      %Static{candidate_generator: default} when is_nil(variant) -> default
      %Static{variants: %{^variant => variant}} -> variant
    end
  end

  @callback refresh_rate(Screen.t() | Screen.app_id()) :: pos_integer() | nil
  @callback refresh_rate(Screen.t() | Screen.app_id(), static_params()) :: pos_integer() | nil
  def refresh_rate(screen_or_app_id, static_params \\ @static_params)

  def refresh_rate(%Screen{app_id: app_id}, static_params),
    do: refresh_rate(app_id, static_params)

  def refresh_rate(app_id, static_params) do
    %Static{refresh_rate: refresh_rate} = Map.fetch!(static_params, app_id)
    refresh_rate
  end

  @callback variants(Screen.t()) :: [String.t()]
  @callback variants(Screen.t(), static_params()) :: [String.t()]
  def variants(%Screen{app_id: app_id}, static_params \\ @static_params) do
    %Static{variants: variants} = Map.fetch!(static_params, app_id)
    Map.keys(variants)
  end
end
