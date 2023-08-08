defmodule Screens.V2.CandidateGenerator.Triptych do
  @moduledoc false

  alias Screens.V2.CandidateGenerator
  alias Screens.V2.Template.Builder

  alias Screens.V2.WidgetInstance.Placeholder

  @behaviour CandidateGenerator

  @impl CandidateGenerator
  def screen_template do
    {:screen,
     %{
       crowding_layout: [:left_two_panes, :third_pane],
       screen_takeover: [:full_screen], # may not be used
       screen_split: [:first_pane, :second_pane, :third_pane]
     }}
    |> Builder.build_template()
  end

  @impl CandidateGenerator
  def candidate_instances(
        _config,
        _now \\ DateTime.utc_now()
      ) do
    [
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
