defmodule Screens.V2.CandidateGenerator.Solari do
  @moduledoc false

  alias Screens.V2.CandidateGenerator
  alias Screens.V2.WidgetInstance.{NormalHeader, Placeholder}

  alias Screens.Config.{Screen, Solari}

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
  def candidate_instances(config) do
    header_instances(config) ++
      [
        %Placeholder{color: :blue, slot_names: [:main_content_normal]}
      ]
  end

  defp header_instances(config) do
    %Screen{app_params: %Solari{station_name: header_text}} = config
    [%NormalHeader{screen: config, text: header_text, time: DateTime.utc_now()}]
  end
end
