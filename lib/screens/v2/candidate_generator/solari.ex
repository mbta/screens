defmodule Screens.V2.CandidateGenerator.Solari do
  @moduledoc false

  alias Screens.V2.CandidateGenerator
  alias Screens.V2.WidgetInstance.Placeholder

  @behaviour CandidateGenerator

  @impl CandidateGenerator
  def screen_template do
    {:screen,
     %{
       normal: [:header_normal, :main_content_normal],
       overhead: [:header_overhead, :main_content_overhead],
       takeover: [:full_screen]
     }}
  end

  @impl CandidateGenerator
  def candidate_instances(_config) do
    [
      %Placeholder{color: :green, slot_names: [:header_normal]},
      %Placeholder{color: :blue, slot_names: [:main_content_normal]}
    ]
  end
end
