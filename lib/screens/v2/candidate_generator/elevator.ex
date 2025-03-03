defmodule Screens.V2.CandidateGenerator.Elevator do
  @moduledoc false

  alias Screens.V2.CandidateGenerator
  alias Screens.V2.CandidateGenerator.Elevator.Closures
  alias Screens.V2.CandidateGenerator.Widgets.Evergreen
  alias Screens.V2.Template.Builder

  @behaviour CandidateGenerator

  @instance_fns [
    &Closures.elevator_status_instances/2,
    &Evergreen.evergreen_content_instances/2
  ]

  @impl true
  def screen_template(_screen) do
    {
      :screen,
      %{
        normal: [
          :header,
          :main_content,
          :footer
        ],
        takeover: [:full_screen]
      }
    }
    |> Builder.build_template()
  end

  @impl true
  def candidate_instances(
        config,
        _query_params,
        now \\ DateTime.utc_now(),
        instance_fns \\ @instance_fns
      ) do
    instance_fns |> Enum.map(& &1.(config, now)) |> Enum.concat()
  end

  @impl true
  def audio_only_instances(_widgets, _config), do: []
end
