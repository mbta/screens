defmodule Screens.V2.CandidateGenerator.Dup do
  @moduledoc false

  alias Screens.Config.{Dup, Screen}
  alias Screens.V2.CandidateGenerator
  alias Screens.V2.WidgetInstance.{NormalHeader, Placeholder}

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
  def candidate_instances(config, now \\ DateTime.utc_now()) do
    header_instances(config, now) ++
      [
        %Placeholder{color: :red, slot_names: [:main_content]}
      ]
  end

  defp header_instances(config, now) do
    %Screen{app_params: %Dup{primary: %Dup.Departures{header: header_text}}} = config
    [%NormalHeader{screen: config, icon: :logo, text: header_text, time: now}]
  end
end
