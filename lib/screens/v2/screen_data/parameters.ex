defmodule Screens.V2.ScreenData.Parameters do
  @moduledoc false

  alias Screens.V2.CandidateGenerator

  @type candidate_generator :: module()

  @app_id_to_candidate_generator %{
    bus_eink_v2: CandidateGenerator.BusEink,
    bus_shelter_v2: CandidateGenerator.BusShelter,
    gl_eink_v2: CandidateGenerator.GlEink,
    solari_v2: CandidateGenerator.Solari,
    solari_large_v2: CandidateGenerator.SolariLarge,
    pre_fare_v2: CandidateGenerator.PreFare,
    dup_v2: CandidateGenerator.Dup,
    triptych_v2: CandidateGenerator.Triptych
  }

  @app_id_to_refresh_rate %{
    bus_eink_v2: 30,
    bus_shelter_v2: 20,
    gl_eink_v2: 30,
    solari_v2: 15,
    solari_large_v2: 15,
    pre_fare_v2: 20,
    dup_v2: 30,
    triptych_v2: 30
  }

  @app_id_to_audio_readout_interval %{
    bus_eink_v2: 0,
    bus_shelter_v2: 5,
    gl_eink_v2: 0,
    solari_v2: 0,
    solari_large_v2: 0,
    pre_fare_v2: 0,
    dup_v2: 0,
    triptych_v2: 0
  }

  # This list should contain IDs of all apps that can show any widget that implements `Screens.V2.AlertsWidget`.
  @apps_that_show_alerts [
    :bus_eink_v2,
    :bus_shelter_v2,
    :gl_eink_v2,
    :pre_fare_v2,
    :dup_v2
  ]

  @spec get_candidate_generator(Screens.Config.Screen.t() | atom()) :: candidate_generator()
  def get_candidate_generator(%Screens.Config.Screen{app_id: app_id}) do
    get_candidate_generator(app_id)
  end

  def get_candidate_generator(app_id) do
    Map.get(@app_id_to_candidate_generator, app_id)
  end

  @spec get_refresh_rate(Screens.Config.Screen.t() | atom()) :: pos_integer() | nil
  def get_refresh_rate(%Screens.Config.Screen{app_id: app_id}) do
    get_refresh_rate(app_id)
  end

  def get_refresh_rate(app_id) do
    Map.get(@app_id_to_refresh_rate, app_id)
  end

  @spec get_audio_readout_interval(Screens.Config.Screen.t() | atom()) :: pos_integer() | nil
  def get_audio_readout_interval(%Screens.Config.Screen{app_id: app_id}) do
    get_refresh_rate(app_id)
  end

  def get_audio_readout_interval(app_id) do
    Map.get(@app_id_to_audio_readout_interval, app_id)
  end

  @doc """
  Returns true for screen types that can show any widget that implements `Screens.V2.AlertsWidget`.
  """
  @spec shows_alerts?(Screens.Config.Screen.t() | atom()) :: boolean()
  def shows_alerts?(%Screens.Config.Screen{app_id: app_id}) do
    shows_alerts?(app_id)
  end

  def shows_alerts?(app_id) do
    app_id in @apps_that_show_alerts
  end

  @spec get_audio_interval_offset_seconds(Screens.Config.Screen.t()) :: pos_integer()
  def get_audio_interval_offset_seconds(%Screens.Config.Screen{
        app_params: %Screens.Config.V2.BusShelter{
          audio: %Screens.Config.V2.Audio{interval_offset_seconds: interval_offset_seconds}
        }
      }) do
    interval_offset_seconds
  end

  def get_audio_interval_offset_seconds(_screen), do: 0
end
