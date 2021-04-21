defmodule Screens.V2.CandidateGenerator.GlEinkDouble do
  @moduledoc false

  alias Screens.Config.{Gl, Screen}
  alias Screens.V2.CandidateGenerator
  alias Screens.V2.WidgetInstance.{FareInfoFooter, Placeholder}

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
      footer_instances(config) ++
      [
        %Placeholder{color: :blue, slot_names: [:main_content]},
        %Placeholder{color: :green, slot_names: [:medium_flex]}
      ]
  end

  defp footer_instances(%Screen{app_params: %Gl{stop_id: stop_id}} = config) do
    [
      %FareInfoFooter{
        screen: config,
        mode: :subway,
        text: "For real-time predictions and fare purchase locations:",
        url: "mbta.com/stops/#{stop_id}"
      }
    ]
  end
end
