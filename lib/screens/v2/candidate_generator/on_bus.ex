defmodule Screens.V2.CandidateGenerator.OnBus do
  @moduledoc false

  alias Screens.V2.CandidateGenerator
  alias Screens.V2.CandidateGenerator.Widgets.OnBus
  alias Screens.V2.Template.Builder
  alias Screens.V2.WidgetInstance.Placeholder

  @behaviour CandidateGenerator

  @impl true
  def screen_template(_screen) do
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
  def candidate_instances(
        config,
        query_params,
        departures_instances_fn \\ &OnBus.Departures.departures_candidate/3
      ) do
    [
      fn -> body_instances(query_params) end,
      fn -> departures_instances_fn.(config, query_params.route_id, query_params.stop_id) end
    ]
    |> Task.async_stream(& &1.())
    |> Enum.flat_map(fn {:ok, instances} -> instances end)
  end

  def body_instances(query_params) do
    [%Placeholder{color: :blue, slot_names: [:main_content], text: build_body_text(query_params)}]
  end

  defp build_body_text(query_params) do
    "Route ID: " <>
      (query_params.route_id || "N/A") <>
      ", Stop ID:  " <>
      (query_params.stop_id || "N/A") <>
      ", Trip ID:  " <>
      (query_params.trip_id || "N/A") <>
      ", Vehicle ID:  " <> (query_params.vehicle_id || "N/A")
  end

  @impl CandidateGenerator
  def audio_only_instances(_widgets, _config), do: []
end
