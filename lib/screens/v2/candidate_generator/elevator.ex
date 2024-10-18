defmodule Screens.V2.CandidateGenerator.Elevator do
  @moduledoc false

  alias Screens.V2.CandidateGenerator
  alias Screens.V2.Template.Builder
  alias Screens.V2.WidgetInstance.{ElevatorClosures, Footer, NormalHeader}
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
        ]
      }
    }
    |> Builder.build_template()
  end

  def candidate_instances(config, now \\ DateTime.utc_now()) do
    [header_instance(config, now), elevator_closures_instance(config), footer_instance(config)]
  end

  def audio_only_instances(_widgets, _config), do: []

  defp elevator_closures_instance(config) do
    %ElevatorClosures{screen: config, alerts: []}
  end

  defp header_instance(%Screen{app_params: %Elevator{elevator_id: elevator_id}} = config, now) do
    %NormalHeader{text: "Elevator #{elevator_id}", screen: config, time: now}
  end

  defp footer_instance(config) do
    %Footer{screen: config}
  end
end
