defmodule Screens.V2.CandidateGenerator.DupNew do
  @moduledoc false

  alias Screens.V2.CandidateGenerator
  alias Screens.V2.CandidateGenerator.Widgets

  alias __MODULE__.Departures

  @behaviour CandidateGenerator

  @instance_generators [
    &Widgets.Header.instances/2,
    &Departures.instances/2,
    &Widgets.Evergreen.evergreen_content_instances/2
  ]

  @impl CandidateGenerator
  defdelegate screen_template(screen), to: Screens.V2.CandidateGenerator.Dup

  @impl CandidateGenerator
  def candidate_instances(config, now \\ DateTime.utc_now()) do
    @instance_generators
    |> Task.async_stream(& &1.(config, now))
    |> Enum.flat_map(fn {:ok, instances} -> instances end)
  end

  @impl CandidateGenerator
  def audio_only_instances(_widgets, _config), do: []
end
