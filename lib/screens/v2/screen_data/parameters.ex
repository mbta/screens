defmodule Screens.V2.ScreenData.Parameters do
  @moduledoc false

  alias Screens.V2.CandidateGenerator

  @type candidate_generator :: module()

  @app_id_to_candidate_generator %{
    bus_eink_v2: CandidateGenerator.BusEink,
    bus_shelter_v2: CandidateGenerator.BusShelter,
    gl_eink_v2: CandidateGenerator.GlEink,
    solari_v2: CandidateGenerator.Solari,
    solari_large_v2: CandidateGenerator.SolariLarge
  }

  @app_id_to_refresh_rate %{
    bus_eink_v2: 30,
    bus_shelter_v2: 20,
    gl_eink_v2: 30,
    solari_v2: 15,
    solari_large_v2: 15
  }

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
end
