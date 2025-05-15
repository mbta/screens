defmodule Screens.V2.CandidateGenerator.Busway do
  @moduledoc false

  alias Screens.V2.CandidateGenerator
  alias Screens.V2.CandidateGenerator.Widgets
  alias Screens.V2.Template.Builder

  @behaviour CandidateGenerator

  @instance_fns [
    &Widgets.Departures.departures_instances/2,
    &Widgets.Evergreen.evergreen_content_instances/2,
    &Widgets.Header.instances/2
  ]

  @impl CandidateGenerator
  def screen_template(_screen) do
    {
      :screen,
      %{
        normal: [:header, :main_content],
        takeover: [:full_screen]
      }
    }
    |> Builder.build_template()
  end

  @impl CandidateGenerator
  def candidate_instances(
        config,
        now \\ DateTime.utc_now(),
        instance_fns \\ @instance_fns
      ) do
    instance_fns
    |> Task.async_stream(& &1.(config, now), timeout: 15_000)
    |> Enum.flat_map(fn {:ok, instances} -> instances end)
  end

  @impl CandidateGenerator
  def audio_only_instances(_widgets, _config), do: []
end
