defmodule Screens.V2.CandidateGenerator.OnBus do
  @moduledoc false

  alias Screens.V2.CandidateGenerator
  alias Screens.V2.Template.Builder
  alias Screens.V2.WidgetInstance.Placeholder

  @behaviour CandidateGenerator

  @impl true
  @spec screen_template() ::
          atom()
          | {atom() | non_neg_integer() | {non_neg_integer(), atom()},
             atom() | %{optional(atom()) => list()}}
  def screen_template do
    {
      :screen,
      %{
        body: [
          :placeholder
        ]
      }
    }
    |> Builder.build_template()
  end

  @impl CandidateGenerator
  def candidate_instances(_config, _now \\ DateTime.utc_now()) do
    [
      %Placeholder{color: "blue", slot_names: [:placeholder], priority: 1}
    ]
  end

  @impl CandidateGenerator
  def audio_only_instances(_widgets, _config), do: []
end
