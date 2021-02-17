defmodule Screens.V2.CandidateGenerator.BusShelter do
  @moduledoc false

  alias Screens.V2.ScreenData

  @spec candidate_templates() :: ScreenData.candidate_templates()
  def candidate_templates do
    :ok
  end

  @spec candidate_instances(ScreenData.config()) :: ScreenData.candidate_instances()
  def candidate_instances(:ok) do
    :ok
  end
end
