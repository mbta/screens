defmodule Screens.V2.CandidateGenerator.OnBus do
  @moduledoc false

  alias Screens.V2.CandidateGenerator
  alias Screens.V2.Template.Builder
  alias Screens.V2.WidgetInstance.Placeholder

  @behaviour CandidateGenerator

  @impl true
  def screen_template do
    {
      :screen,
      %{
        screen_normal: [
          {:body,
           %{
             body_normal: [
               :main_content
             ]
           }}
        ]
      }
    }
    |> Builder.build_template()
  end

  @impl CandidateGenerator
  def candidate_instances(_config, _now \\ DateTime.utc_now()) do
    [
      fn -> body_instances() end
    ]
    |> Task.async_stream(& &1.())
    |> Enum.flat_map(fn {:ok, instances} -> instances end)
  end

  def body_instances() do
    [%Placeholder{color: :blue, slot_names: [:main_content], text: "placeholder text"}]
  end

  @impl CandidateGenerator
  def audio_only_instances(_widgets, _config), do: []
end
