defmodule Screens.V2.CandidateGenerator.PreFare do
  @moduledoc false

  alias Screens.V2.CandidateGenerator
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
              :main_content_left
            ],
            screen_takeover_left: [
              :full_screen_left
            ],
            body_takeover_left: [:full_body_left]
          }},
         {:right,
          %{
            screen_normal_right: [
              :header_right,
              {:body,
               %{
                 body_normal: [
                   :lower_right,
                   Builder.with_paging(
                     {:upper_right,
                      %{
                        one_large: [:large],
                        two_medium: [:medium_left, :medium_right]
                      }},
                     2
                   )
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
  def candidate_instances(_config) do
    [fn -> placeholder_instances() end]
    |> Task.async_stream(& &1.(), ordered: false, timeout: :infinity)
    |> Enum.flat_map(fn {:ok, instances} -> instances end)
  end

  defp placeholder_instances do
    [
      %Placeholder{color: :green, slot_names: [:header_left]},
      %Placeholder{color: :blue, slot_names: [:header_right]},
      %Placeholder{color: :red, slot_names: [:main_content_left]},
      %Placeholder{color: :yellow, slot_names: [:body_placeholder]},
      %Placeholder{color: :red, slot_names: [:secondary_content]},
      %Placeholder{color: :black, slot_names: [:main_content_right]},
      %Placeholder{color: :gray, slot_names: [:full_screen_right]},
      %Placeholder{color: :gray, slot_names: [:full_screen_left]},
      %Placeholder{color: :orange, slot_names: [:full_body]}
    ]
  end
end
