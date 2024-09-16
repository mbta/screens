defmodule Screens.V2.CandidateGenerator.DupNew do
  @moduledoc false

  alias Screens.V2.CandidateGenerator
  alias Screens.V2.CandidateGenerator.Dup, as: DupBase
  alias Screens.V2.WidgetInstance.Placeholder

  @behaviour CandidateGenerator

  @impl CandidateGenerator
  defdelegate screen_template(), to: DupBase

  @impl CandidateGenerator
  def candidate_instances(_config) do
    List.duplicate(
      %Placeholder{
        color: :gray,
        slot_names: [:full_rotation_zero, :full_rotation_one, :full_rotation_two]
      },
      3
    )
  end

  @impl CandidateGenerator
  def audio_only_instances(_widgets, _config), do: []
end
