defmodule Screens.V2.CandidateGenerator.PreFare do
  @moduledoc false

  alias Screens.Config.Screen
  alias Screens.Config.V2.Header.CurrentStopName
  alias Screens.Config.V2.PreFare
  alias Screens.V2.CandidateGenerator
  alias Screens.V2.CandidateGenerator.Widgets
  alias Screens.V2.Template.Builder
  alias Screens.V2.WidgetInstance.{NormalHeader, Placeholder}

  @behaviour CandidateGenerator

  @impl CandidateGenerator
  def screen_template do
    {:screen,
     %{
       screen_normal: [
         :header,
         {:body,
          %{
            body_normal: [
              {:body_left,
               %{
                 body_left_normal: [:main_content_left],
                 body_left_takeover: [:full_body_left]
               }},
              {:body_right,
               %{
                 body_right_normal: [
                   Builder.with_paging(
                     {:upper_right,
                      %{
                        one_large: [:large],
                        two_medium: [:medium_left, :medium_right]
                      }},
                     2
                   ),
                   :lower_right
                 ],
                 body_right_takeover: [:full_body_right]
               }}
            ],
            body_takeover: [:full_body]
          }}
       ],
       screen_takeover: [:full_screen]
     }}
    |> Builder.build_template()
  end

  @impl CandidateGenerator
  def candidate_instances(
        config,
        now \\ DateTime.utc_now(),
        elevator_status_instances_fn \\ &Widgets.ElevatorClosures.elevator_status_instances/2
      ) do
    [
      fn -> header_instances(config, now) end,
      fn -> elevator_status_instances_fn.(config, now) end,
      fn -> placeholder_instances() end
    ]
    |> Task.async_stream(& &1.(), ordered: false, timeout: :infinity)
    |> Enum.flat_map(fn {:ok, instances} -> instances end)
  end

  defp header_instances(config, now) do
    %Screen{app_params: %PreFare{header: %CurrentStopName{stop_name: stop_name}}} = config

    [%NormalHeader{screen: config, text: stop_name, time: now}]
  end

  defp placeholder_instances do
    [
      %Placeholder{color: :red, slot_names: [:main_content_left]},
      %Placeholder{color: :red, slot_names: [:upper_right]},
      %Placeholder{color: :red, slot_names: [:large]},
      %Placeholder{color: :red, slot_names: [:medium_left]},
      %Placeholder{color: :red, slot_names: [:medium_right]},
      %Placeholder{color: :black, slot_names: [:lower_right]},
      %Placeholder{color: :gray, slot_names: [:full_screen]},
      %Placeholder{color: :blue, slot_names: [:full_body]},
      %Placeholder{color: :orange, slot_names: [:full_body_left]},
      %Placeholder{color: :orange, slot_names: [:full_body_right]}
    ]
  end
end
