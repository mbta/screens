defmodule Screens.V2.CandidateGenerator.DupNew do
  @moduledoc false

  alias Screens.Telemetry
  alias Screens.V2.CandidateGenerator
  alias Screens.V2.CandidateGenerator.Widgets.Evergreen
  alias __MODULE__.{Departures, Header}

  @behaviour CandidateGenerator

  @telemetry_name ~w[screens v2 candidate_generator dup_new]a
  @instance_generators [
                         header_instances: &Header.instances/2,
                         departures_instances: &Departures.instances/2,
                         evergreen_instances: &Evergreen.evergreen_content_instances/2
                       ]
                       |> Enum.map(fn {name, func} -> {@telemetry_name ++ [name], func} end)

  @impl CandidateGenerator
  defdelegate screen_template(screen), to: Screens.V2.CandidateGenerator.Dup

  @impl CandidateGenerator
  def candidate_instances(config, _query_params, now \\ DateTime.utc_now()) do
    Telemetry.span(@telemetry_name, fn ->
      context = Telemetry.context()

      @instance_generators
      |> Task.async_stream(fn {name, func} ->
        Telemetry.span(name, context, fn -> func.(config, now) end)
      end)
      |> Enum.flat_map(fn {:ok, instances} -> instances end)
    end)
  end

  @impl CandidateGenerator
  def audio_only_instances(_widgets, _config), do: []
end
