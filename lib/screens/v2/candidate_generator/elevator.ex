defmodule Screens.V2.CandidateGenerator.Elevator do
  @moduledoc false

  alias Screens.V2.CandidateGenerator
  alias Screens.V2.Template.Builder
  alias Screens.V2.WidgetInstance.ElevatorClosures

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

  def candidate_instances(config) do
    elevator_closures_instances(config)
  end

  def audio_only_instances(_widgets, _config), do: []

  defp elevator_closures_instances(config) do
    [%ElevatorClosures{screen: config, alerts: []}]
  end
end
