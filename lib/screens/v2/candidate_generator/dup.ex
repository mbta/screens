defmodule Screens.V2.CandidateGenerator.Dup do
  @moduledoc false

  alias Screens.V2.CandidateGenerator
  alias Screens.V2.WidgetInstance.Placeholder

  @behaviour CandidateGenerator

  @impl CandidateGenerator
  def screen_template do
    {:screen,
     %{
       normal: [:header, :main_content],
       full_takeover: [:full_screen]
     }}
  end

  @impl CandidateGenerator
  def candidate_instances(_config) do
    [
      %Placeholder{color: :grey, slot_names: [:header]},
      %Placeholder{color: :red, slot_names: [:main_content]}
    ]
  end
end
