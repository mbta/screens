defmodule Screens.V2.CandidateGenerator.Elevator do
  @moduledoc false

  alias Screens.V2.CandidateGenerator
  alias Screens.V2.Template.Builder
  alias Screens.V2.WidgetInstance.Placeholder

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

  def candidate_instances(_config) do
    [fn -> placeholder_instances() end]
    |> Task.async_stream(& &1.(), timeout: 15_000)
    |> Enum.flat_map(fn {:ok, instances} -> instances end)
  end

  def audio_only_instances(_widgets, _config), do: []

  defp placeholder_instances do
    [
      %Placeholder{color: :blue, slot_names: [:main_content]}
    ]
  end
end
