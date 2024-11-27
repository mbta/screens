defmodule Screens.V2.CandidateGenerator.Elevator do
  @moduledoc false

  alias Screens.V2.CandidateGenerator
  alias Screens.V2.CandidateGenerator.Elevator.Closures, as: ElevatorClosures
  alias Screens.V2.CandidateGenerator.Widgets.Evergreen
  alias Screens.V2.Template.Builder

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

  def candidate_instances(
        config,
        now \\ DateTime.utc_now(),
        elevator_closure_instances_fn \\ &ElevatorClosures.elevator_status_instances/2,
        evergreen_content_instances_fn \\ &Evergreen.evergreen_content_instances/2
      ) do
    Enum.concat([
      elevator_closure_instances_fn.(config, now),
      evergreen_content_instances_fn.(config, now)
    ])
  end

  def audio_only_instances(_widgets, _config), do: []
end
