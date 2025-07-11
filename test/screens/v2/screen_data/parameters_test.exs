defmodule Screens.V2.ScreenData.ParametersTest do
  use ExUnit.Case, async: true

  alias Screens.V2.ScreenData.{Parameters, Static}
  alias Screens.V2.ScreenData.Static.PeriodicAudio
  alias ScreensConfig, as: Config
  alias ScreensConfig.Screen

  defp build_params(static_fields) do
    %{bus_shelter_v2: struct!(%Static{candidate_generator: nil, refresh_rate: 0}, static_fields)}
  end

  defp build_periodic_audio(fields) do
    struct!(
      %PeriodicAudio{
        day_volume: 1.0,
        interval_minutes: 7,
        night_time: {~T[00:00:00], ~T[00:00:00]},
        night_volume: 0.5
      },
      fields
    )
  end

  defp build_screen(app_params \\ %{}) do
    %Screen{
      app_id: :bus_shelter_v2,
      app_params:
        struct!(
          %Screen.BusShelter{
            alerts: %Config.Alerts{stop_id: "1"},
            departures: %Config.Departures{sections: []},
            footer: %Config.Footer{},
            header: %Config.Header.StopId{stop_id: "1"},
            audio: %Config.Audio{
              interval_enabled: true
            }
          },
          app_params
        ),
      device_id: "TEST",
      name: "TEST",
      vendor: :lg_mri
    }
  end

  # actual "now" passed into these functions may not already be in the Eastern time zone
  defp local_time(time),
    do: DateTime.new!(~D[2024-01-01], time, "America/New_York") |> DateTime.shift_zone!("Etc/UTC")

  describe "audio_enabled?/2" do
    test "is false for a screen type with no audio schedule" do
      static_params = build_params(audio_active_time: nil)
      refute Parameters.audio_enabled?(build_screen(), DateTime.utc_now(), static_params)
    end

    test "is false outside the screen type's audio schedule" do
      static_params = build_params(audio_active_time: {~T[06:00:00], ~T[08:00:00]})
      refute Parameters.audio_enabled?(build_screen(), local_time(~T[09:00:00]), static_params)
    end

    test "is true within the screen type's audio schedule" do
      static_params = build_params(audio_active_time: {~T[06:00:00], ~T[08:00:00]})
      assert Parameters.audio_enabled?(build_screen(), local_time(~T[07:00:00]), static_params)
    end
  end

  describe "audio_interval_minutes/1" do
    test "is nil for a screen type without periodic audio" do
      static_params = build_params(periodic_audio: nil)
      screen = build_screen()
      assert Parameters.audio_interval_minutes(screen, static_params) == nil
    end

    test "is the configured interval for a screen type with periodic audio" do
      static_params = build_params(periodic_audio: build_periodic_audio(interval_minutes: 7))
      screen = build_screen()
      assert Parameters.audio_interval_minutes(screen, static_params) == 7
    end

    test "is nil for a screen with audio interval disabled" do
      screen = build_screen(%{audio: %Config.Audio{interval_enabled: false}})
      assert Parameters.audio_interval_minutes(screen) == nil
    end
  end

  describe "audio_interval_offset_seconds/1" do
    test "is nil for a screen without periodic audio" do
      screen = build_screen(audio: nil)
      assert Parameters.audio_interval_offset_seconds(screen) == nil
    end

    test "is the configured offset for a screen with periodic audio" do
      screen = build_screen(audio: %Config.Audio{interval_offset_seconds: 90})
      assert Parameters.audio_interval_offset_seconds(screen) == 90
    end
  end

  describe "audio_volume/2" do
    setup do
      %{
        static_params:
          build_params(
            periodic_audio:
              build_periodic_audio(
                day_volume: 1.0,
                night_time: {~T[22:00:00], ~T[04:00:00]},
                night_volume: 0.5
              )
          )
      }
    end

    test "is nil for a screen type without periodic audio" do
      now = local_time(~T[00:00:00])
      static_params = build_params(periodic_audio: nil)
      assert Parameters.audio_volume(build_screen(), now, static_params) == nil
    end

    test "is the day volume when it is not nighttime", %{static_params: static_params} do
      now = local_time(~T[10:00:00])
      assert Parameters.audio_volume(build_screen(), now, static_params) == 1.0
    end

    test "is the night volume when it is nighttime", %{static_params: static_params} do
      now = local_time(~T[01:00:00])
      assert Parameters.audio_volume(build_screen(), now, static_params) == 0.5
    end
  end

  describe "candidate_generator/2" do
    test "returns the candidate generator for a screen type" do
      static_params = build_params(candidate_generator: :default)
      assert Parameters.candidate_generator(build_screen(), nil, static_params) == :default
    end

    test "returns a variant candidate generator" do
      static_params = build_params(candidate_generator: :default, variants: %{"test" => :variant})
      assert Parameters.candidate_generator(build_screen(), "test", static_params) == :variant
    end
  end

  describe "refresh_rate/1" do
    test "returns the configured refresh rate for a screen type" do
      static_params = build_params(refresh_rate: 25)
      assert Parameters.refresh_rate(build_screen(), static_params) == 25
    end
  end

  describe "variants/1" do
    test "returns the list of variants for a screen type" do
      static_params = build_params(variants: %{"one" => :test1, "two" => :test2})
      assert Parameters.variants(build_screen(), static_params) == ["one", "two"]
    end
  end
end
