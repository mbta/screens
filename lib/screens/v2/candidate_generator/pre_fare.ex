defmodule Screens.V2.CandidateGenerator.PreFare do
  @moduledoc false

  alias Screens.V2.CandidateGenerator
  alias Screens.V2.CandidateGenerator.Widgets
  alias Screens.V2.Template.Builder
  alias Screens.V2.WidgetInstance.Placeholder

  @behaviour CandidateGenerator

  @impl CandidateGenerator
  def screen_template do
    {:screen,
     %{
       top_level: [
         {:left,
          %{
            screen_normal_left: [
              :header_left,
              {:body_left,
               %{
                 body_normal_left: [:main_content_left],
                 body_takeover_left: [:full_body_left]
               }}
            ],
            screen_takeover_left: [
              :full_screen_left
            ]
          }},
         {:right,
          %{
            screen_normal_right: [
              :header_right,
              {:body_right,
               %{
                 body_normal_right: [
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
                 body_takeover_right: [:full_body_right]
               }}
            ],
            screen_takeover_right: [
              :full_screen_right
            ]
          }}
       ]
     }}
    |> Builder.build_template()
  end

  @impl CandidateGenerator
  def candidate_instances(
        config,
        now \\ DateTime.utc_now(),
        elevator_status_instances_fn \\ &Widgets.ElevatorClosures.elevator_status_instances/2
      ) do
    [fn -> elevator_status_instances_fn.(config, now) end, fn -> placeholder_instances() end]
    |> Task.async_stream(& &1.(), ordered: false, timeout: :infinity)
    |> Enum.flat_map(fn {:ok, instances} -> instances end)
  end

  defp placeholder_instances do
    [
      %Placeholder{color: :green, slot_names: [:header_left]},
      %Placeholder{color: :blue, slot_names: [:header_right]},
      %Placeholder{color: :red, slot_names: [:main_content_left]},
      %Placeholder{color: :red, slot_names: [:large]},
      %Placeholder{color: :red, slot_names: [:medium_left]},
      %Placeholder{color: :red, slot_names: [:medium_right]},
      %Placeholder{color: :black, slot_names: [:lower_right]},
      %Placeholder{color: :gray, slot_names: [:full_screen_right]},
      %Placeholder{color: :gray, slot_names: [:full_screen_left]},
      %Placeholder{color: :orange, slot_names: [:full_body_left]},
      %Placeholder{color: :orange, slot_names: [:full_body_right]}
    ]
  end
end
