defmodule Screens.V2.CandidateGenerator.SolariLarge do
  @moduledoc false

  alias Screens.V2.CandidateGenerator
  alias Screens.V2.Template.Builder
  alias Screens.V2.WidgetInstance.{NormalHeader, Placeholder}

  alias Screens.Config.{Screen, Solari}

  @behaviour CandidateGenerator

  @impl CandidateGenerator
  def screen_template do
    {:screen,
     %{
       normal: [:header, :main_content],
       takeover: [:full_screen]
     }}
    |> Builder.build_template()
  end

  @impl CandidateGenerator
  def candidate_instances(config, now \\ DateTime.utc_now()) do
    header_instances(config, now) ++
      [
        %Placeholder{color: :blue, slot_names: [:main_content]}
      ]
  end

  defp header_instances(config, now) do
    %Screen{app_params: %Solari{station_name: header_text}} = config
    [%NormalHeader{screen: config, text: header_text, time: now}]
  end
end
