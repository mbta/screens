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
       screen_normal: [
         :left_header,
         :right_header,
         {:body,
          %{
            left_body_normal: [
              :main_content
            ],
            right_body_normal: [
              Builder.with_paging(
                {:flex_zone,
                 %{
                   one_extra_large_one_large: [:extra_large, :large],
                   one_extra_large_two_medium: [:extra_large, :medium_left, :medium_right],
                   one_extra_large_one_medium_two_small: [
                     :extra_large,
                     :medium_left,
                     :small_upper_right,
                     :small_lower_right
                   ]
                 }},
                3
              )
            ],
            right_body_takeover: [:full_body]
          }}
       ],
       left_screen_takeover: [:full_screen],
       right_screen_takeover: [:full_screen]
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
      %Placeholder{color: :green, slot_names: [:left_header]},
      %Placeholder{color: :blue, slot_names: [:right_header]},
      %Placeholder{color: :red, slot_names: [:main_content]},
      %Placeholder{color: :yellow, slot_names: [:extra_large]},
      %Placeholder{color: :orange, slot_names: [:large]},
      %Placeholder{color: :pink, slot_names: [:medium_left]},
      %Placeholder{color: :black, slot_names: [:medium_right]},
      %Placeholder{color: :purple, slot_names: [:small_upper_right]},
      %Placeholder{color: :gray, slot_names: [:small_lower_right]}
    ]
  end
end
