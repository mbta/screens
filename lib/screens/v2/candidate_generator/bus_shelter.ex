defmodule Screens.V2.CandidateGenerator.BusShelter do
  @moduledoc false

  alias Screens.V2.CandidateGenerator

  @behaviour CandidateGenerator

  @impl CandidateGenerator
  def candidate_templates do
    :ok
  end

  @impl CandidateGenerator
  def candidate_instances(:ok) do
    :ok
  end
end
