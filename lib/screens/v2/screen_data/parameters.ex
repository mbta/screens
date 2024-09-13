defmodule Screens.V2.ScreenData.Parameters do
  @moduledoc false

  alias Screens.V2.CandidateGenerator

  @type candidate_generator :: module()

  @app_id_to_candidate_generator %{
    bus_eink_v2: CandidateGenerator.BusEink,
    bus_shelter_v2: CandidateGenerator.BusShelter,
    gl_eink_v2: CandidateGenerator.GlEink,
    busway_v2: CandidateGenerator.Busway,
    solari_large_v2: CandidateGenerator.SolariLarge,
    pre_fare_v2: CandidateGenerator.PreFare,
    dup_v2: CandidateGenerator.Dup,
    triptych_v2: CandidateGenerator.Triptych
  }

  @app_id_to_refresh_rate %{
    bus_eink_v2: 30,
    bus_shelter_v2: 20,
    gl_eink_v2: 30,
    busway_v2: 15,
    solari_large_v2: 15,
    pre_fare_v2: 20,
    dup_v2: 30,
    triptych_v2: 30
  }

  @app_id_to_audio_readout_interval %{
    bus_eink_v2: 0,
    bus_shelter_v2: 5,
    gl_eink_v2: 0,
    busway_v2: 0,
    solari_large_v2: 0,
    pre_fare_v2: 0,
    dup_v2: 0,
    triptych_v2: 0
  }

  @spec get_candidate_generator(ScreensConfig.Screen.t() | atom()) :: candidate_generator()
  def get_candidate_generator(%ScreensConfig.Screen{app_id: app_id}) do
    get_candidate_generator(app_id)
  end

  def get_candidate_generator(app_id) do
    Map.get(@app_id_to_candidate_generator, app_id)
  end

  @spec get_refresh_rate(ScreensConfig.Screen.t() | atom()) :: pos_integer() | nil
  def get_refresh_rate(%ScreensConfig.Screen{app_id: app_id}) do
    get_refresh_rate(app_id)
  end

  def get_refresh_rate(app_id) do
    Map.get(@app_id_to_refresh_rate, app_id)
  end

  @spec get_audio_readout_interval(ScreensConfig.Screen.t() | atom()) :: pos_integer() | nil
  def get_audio_readout_interval(%ScreensConfig.Screen{app_id: app_id}) do
    get_refresh_rate(app_id)
  end

  def get_audio_readout_interval(app_id) do
    Map.get(@app_id_to_audio_readout_interval, app_id)
  end

  @spec get_audio_interval_offset_seconds(ScreensConfig.Screen.t()) :: pos_integer()
  def get_audio_interval_offset_seconds(%ScreensConfig.Screen{
        app_params: %ScreensConfig.V2.BusShelter{
          audio: %ScreensConfig.V2.Audio{interval_offset_seconds: interval_offset_seconds}
        }
      }) do
    interval_offset_seconds
  end

  def get_audio_interval_offset_seconds(_screen), do: 0
end
