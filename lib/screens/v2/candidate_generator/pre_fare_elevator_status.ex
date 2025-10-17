defmodule Screens.V2.CandidateGenerator.PreFareElevatorStatus do
  @moduledoc "Variant candidate generator for the in-development Elevator Status v2 widget."

  alias Screens.V2.CandidateGenerator
  alias Screens.V2.CandidateGenerator.PreFare, as: BaseGenerator
  alias Screens.V2.CandidateGenerator.Widgets

  @behaviour CandidateGenerator

  @instance_fns [
    &CandidateGenerator.PreFare.ElevatorStatus.instances/2,
    &Widgets.Departures.departures_instances/2,
    &Widgets.Evergreen.evergreen_content_instances/2,
    &Widgets.FullLineMap.full_line_map_instances/2,
    &Widgets.Header.instances/2,
    &Widgets.ReconstructedAlert.reconstructed_alert_instances/2,
    &Widgets.SubwayStatus.subway_status_instances/2
  ]

  @impl CandidateGenerator
  defdelegate screen_template(config), to: BaseGenerator

  @impl CandidateGenerator
  def candidate_instances(config, now \\ DateTime.utc_now(), instance_fns \\ @instance_fns) do
    instance_fns
    |> Task.async_stream(& &1.(config, now), timeout: 20_000)
    |> Enum.flat_map(fn {:ok, instances} -> instances end)
  end

  @impl CandidateGenerator
  defdelegate audio_only_instances(widgets, config), to: BaseGenerator
end
