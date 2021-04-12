defmodule Screens.V2.CandidateGenerator.SolariLarge do
  @moduledoc false

  alias Screens.V2.CandidateGenerator
  alias Screens.V2.WidgetInstance.Placeholder

  @behaviour CandidateGenerator

  @impl CandidateGenerator
  def screen_template do
    {:screen,
     %{
       normal: [:header, :main_content],
       takeover: [:full_screen]
     }}
  end

  @impl CandidateGenerator
  def candidate_instances(_config) do
    [
      %Placeholder{color: :green, slot_names: [:header]},
      %Placeholder{color: :blue, slot_names: [:main_content]}
    ]
  end
end
