defmodule Screens.V2.CandidateGenerator.GlEinkDouble do
  @moduledoc false

  alias Screens.V2.CandidateGenerator
  alias Screens.V2.WidgetInstance.Placeholder

  @behaviour CandidateGenerator

  @impl CandidateGenerator
  def screen_template do
    {:screen,
     %{
       normal: [
         :header,
         :main_content,
         :medium_flex,
         :footer
       ],
       bottom_takeover: [
         :header,
         :main_content,
         :bottom_screen
       ],
       full_takeover: [:full_screen]
     }}
  end

  @impl CandidateGenerator
  def candidate_instances(
        config,
        now \\ DateTime.utc_now(),
        fetch_destination_fn \\ &CandidateGenerator.Helpers.fetch_destination/2
      ) do
    CandidateGenerator.Helpers.gl_header_instances(config, now, fetch_destination_fn) ++
      [
        %Placeholder{color: :red, slot_names: [:footer]},
        %Placeholder{color: :blue, slot_names: [:main_content]},
        %Placeholder{color: :green, slot_names: [:medium_flex]}
      ]
  end
end
