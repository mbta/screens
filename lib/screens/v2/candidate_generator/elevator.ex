defmodule Screens.V2.CandidateGenerator.Elevator do
  @moduledoc false

  alias Screens.V2.CandidateGenerator
  alias Screens.V2.Template.Builder
  alias Screens.V2.WidgetInstance.Placeholder

  @behaviour CandidateGenerator

  def screen_template do
    {
      :screen,
      %{
        normal: [:main_content]
      }
    }
    |> Builder.build_template()
  end

  def candidate_instances(_config) do
    placeholder_instances()
  end

  def audio_only_instances(_widgets, _config), do: []

  defp placeholder_instances do
    [
      %Placeholder{color: :blue, slot_names: [:main_content]}
    ]
  end
end
