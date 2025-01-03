defmodule Screens.V2.CandidateGenerator.Elevator do
  @moduledoc false

  alias Screens.V2.CandidateGenerator
  alias Screens.V2.CandidateGenerator.Elevator.Closures, as: ElevatorClosures
  alias Screens.V2.CandidateGenerator.Widgets.Evergreen
  alias Screens.V2.Template.Builder
  alias Screens.V2.WidgetInstance.{Footer, NormalHeader}
  alias ScreensConfig.Screen
  alias ScreensConfig.V2.Elevator

  @behaviour CandidateGenerator

  def screen_template do
    {
      :screen,
      %{
        normal: [
          :header,
          :main_content,
          :footer
        ],
        takeover: [:full_screen]
      }
    }
    |> Builder.build_template()
  end

  def candidate_instances(
        config,
        now \\ DateTime.utc_now(),
        elevator_closure_instances_fn \\ &ElevatorClosures.elevator_status_instances/3,
        evergreen_content_instances_fn \\ &Evergreen.evergreen_content_instances/2
      ) do
    Enum.concat([
      elevator_closure_instances_fn.(
        config,
        header_instance(config, now),
        footer_instance(config)
      ),
      evergreen_content_instances_fn.(config, now)
    ])
  end

  def audio_only_instances(_widgets, _config), do: []

  defp header_instance(%Screen{app_params: %Elevator{elevator_id: elevator_id}} = config, now) do
    %NormalHeader{text: "Elevator #{elevator_id}", screen: config, time: now}
  end

  defp footer_instance(config) do
    %Footer{screen: config}
  end
end
