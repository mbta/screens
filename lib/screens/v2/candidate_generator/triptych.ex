defmodule Screens.V2.CandidateGenerator.Triptych do
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
       screen_normal: [:full_screen],
       screen_split: [:first_pane, :second_pane, :third_pane]
     }}
    |> Builder.build_template()
  end

  @impl CandidateGenerator
  def candidate_instances(
        config,
        _now \\ DateTime.utc_now(),
        crowding_widget_instances_fn \\ &Widgets.TrainCrowding.crowding_widget_instances/1,
        evergreen_content_instances_fn \\ &Widgets.Evergreen.evergreen_content_instances/1
      ) do
    [
      fn -> crowding_widget_instances_fn.(config) end,
      fn -> evergreen_content_instances_fn.(config) end,
      fn -> placeholder_instances() end
    ]
    |> Task.async_stream(& &1.(), ordered: false, timeout: 20_000)
    |> Enum.flat_map(fn {:ok, instances} -> instances end)
  end

  @impl CandidateGenerator
  def audio_only_instances(_widgets, _config), do: []

  defp placeholder_instances do
    [
      %Placeholder{color: :blue, slot_names: [:left_two_panes]},
      %Placeholder{color: :green, slot_names: [:third_pane]}
    ]
  end
end
