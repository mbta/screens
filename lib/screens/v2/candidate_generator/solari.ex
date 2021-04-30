defmodule Screens.V2.CandidateGenerator.Solari do
  @moduledoc false

  alias Screens.Config.Screen
  alias Screens.Config.V2.Header.CurrentStopName
  alias Screens.Config.V2.Solari
  alias Screens.V2.CandidateGenerator
  alias Screens.V2.Template.Builder
  alias Screens.V2.WidgetInstance.{NormalHeader, Placeholder}

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
    %Screen{app_params: %Solari{header: %CurrentStopName{stop_name: stop_name}}} = config

    [%NormalHeader{screen: config, icon: :logo, text: stop_name, time: now}]
  end
end
